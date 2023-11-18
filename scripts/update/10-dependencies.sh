#!/bin/bash
# Ensures that dependencies are installed and corrects them if that is not the case.

# Function to add a repository and trigger an update
add_repository() {
    local repo=$1
    local list_file=$2
    if ! grep -s "$repo" "$list_file" 2> /dev/null | grep -q -v '^#'; then
        echo_info "Adding $repo repo"
        add-apt-repository -y ppa:"$repo" >> "${log}" 2>&1
        trigger_apt_update=true
    fi
}

# Check for add-apt-repository and install if missing
if ! which add-apt-repository > /dev/null; then
    apt_install software-properties-common
fi

# Add repositories based on OS and version
if [[ $(_os_distro) == "ubuntu" ]]; then
    case $(_os_codename) in
        "jammy")
            add_repository "ubuntu-toolchain-r/ppa" "/etc/apt/sources.list.d/ubuntu-toolchain-r-ubuntu-ppa-jammy.list"
            add_repository "ondrej/nginx" "/etc/apt/sources.list.d/ondrej-ubuntu-nginx-jammy.list"
            add_repository "ondrej/php" "/etc/apt/sources.list.d/ondrej-ubuntu-php-jammy.list"
            ;;
    esac

    # Enable universe, multiverse, and restricted repositories
    for repo in universe multiverse restricted; do
        if ! grep "$repo" /etc/apt/sources.list | grep -q -v '^#'; then
            echo_info "Enabling $repo repo"
            add-apt-repository -y "$repo" >> "${log}" 2>&1
            trigger_apt_update=true
        fi
    done
elif [[ $(_os_distro) == "debian" ]]; then
    for repo in contrib non-free; do
        if ! grep "$repo" /etc/apt/sources.list | grep -q -v '^#'; then
            echo_info "Enabling $repo repo"
            apt-add-repository -y "$repo" >> "${log}" 2>&1
            trigger_apt_update=true
        fi
    done
fi

# Update package lists if needed
if [[ $trigger_apt_update == "true" ]]; then
    apt_update
fi

# Install dependencies
dependencies="whiptail git sudo curl wget lsof fail2ban apache2-utils vnstat tcl tcl-dev build-essential dirmngr apt-transport-https bc uuid-runtime jq net-tools gnupg2 cracklib-runtime unzip ccze"
apt_install "${dependencies[@]}"

# Upgrade GCC for Jammy
. /etc/swizzin/sources/functions/gcc
GCC_Jammy_Upgrade
