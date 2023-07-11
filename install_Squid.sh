#!/bin/bash

# System update
sudo apt update -y
sudo apt upgrade -y

# Installing Squid & apache2-utils for htpasswd
sudo apt install squid -y
sudo apt install apache2-utils -y

# Saving the original Squid configuration file
sudo mv /etc/squid/squid.conf /etc/squid/squid.conf.original

# Checking the presence of the parameter
if [ $# -eq 0 ]; then
    echo "No password specified."

# Actions to be taken if no parameters are supplied

    # Configuring Squid for operation without authentication
    sudo bash -c 'echo "
        http_port 3128
        acl all_traffic src all
        http_access allow all_traffic
        access_log /var/log/squid/access.log
        " > /etc/squid/squid.conf'
else
    echo "The specified password is : $1"

# The specified password is

    # Path to password file
    htpasswd_file="/etc/squid/passwd"

    # Create password file if none exists
        if [ ! -f "$htpasswd_file" ]; then
            sudo touch $htpasswd_file
            sudo chmod 777 $htpasswd_file
            exit 1
        fi
    
    # Add user and password to password file
    htpasswd -b "$htpasswd_file" "user" "$1"
    
    # Checking whether the htpasswd command has been executed successfully
    if [ "$?" -eq 0 ]; then
        echo "The user has been successfully added to the password file."
    else
        echo "An error occurred when adding the user to the password file."
    fi

    # Configuring Squid for operation with authentication
    sudo bash -c 'echo "
    auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
    auth_param basic realm Squid proxy-caching web server
    auth_param basic credentialsttl 24 hours
    auth_param basic casesensitive off
    acl authenticated proxy_auth REQUIRED
    http_access allow authenticated
    http_access deny all
    dns_v4_first on
    forwarded_for delete
    via off
    http_port 3128
    " > /etc/squid/squid.conf'

fi

# Restarting the Squid service
sudo systemctl restart squid

# Activate Squid service on startup
sudo systemctl enable squid

