#!/bin/bash

# Exit on error, treat unset variables as an error, and propagate pipeline errors
set -euo pipefail

# Function to display help message
display_help() {
    echo "Usage: $0 -c <config_file>"
    echo "  -c, --config <config_file>  Specify the configuration file."
    echo "                              (Note: This script currently validates the presence of the config file."
    echo "                               Future versions might read specific settings from it.)"
}
# Parse options
config_file=""
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -c|--config) config_file="$2"; shift ;;
        *) echo "Unknown option: $1"; display_help; exit 1 ;;
    esac
    shift
done

# If config file is not specified, display an error message and exit
if [ -z "$config_file" ]; then
    echo "Error: Configuration file not specified."
    display_help
    exit 1
fi

# Display the message
echo "We trust you have received the usual lecture from the local System Administrator. It usually boils down to these three things:"
echo ""
echo "    #1) Respect the privacy of others."
echo "    #2) Think before you type."
echo "    #3) With great power comes great responsibility."
echo ""

# Function to clear DNS cache
clear_dns_cache() {
    if systemctl is-active --quiet systemd-resolved; then
        echo "Restarting systemd-resolved to clear DNS cache..."
        sudo systemctl daemon-reload
        sudo systemctl restart systemd-resolved
        echo "DNS cache cleared."
    elif systemctl is-active --quiet dnsmasq; then
        echo "Restarting dnsmasq to clear DNS cache..."
        sudo systemctl restart dnsmasq
        echo "DNS cache cleared."
    elif systemctl is-active --quiet nscd; then
        echo "Restarting nscd to clear DNS cache..."
        sudo systemctl restart nscd
        echo "DNS cache cleared."
    else
        echo "No known DNS caching service is active."
        exit 1
    fi
}
# If config file does not exist, display an error message and exit
if [ ! -f "$config_file" ]; then
    echo "Error: Configuration file not found: $config_file"
    exit 1
fi


# Call the function to clear DNS cache
clear_dns_cache

# Task 1: Down and up 'eth' or 'enp' interfaces

# Get the list of interfaces that match 'eth' or 'enp'
eth_enp_interfaces=$(nmcli -t -f DEVICE device status | grep -E '^(eth|enp)' | cut -d: -f1)

# Loop through each interface and bring it down and up
for iface in $eth_enp_interfaces; do
    echo "Bringing down interface: $iface"
    sudo nmcli device disconnect "$iface"
    
    echo "Bringing up interface: $iface"
    sudo nmcli device connect "$iface"
done

# Task 2: List interfaces with both IPv4 and IPv6 addresses

# Get the full output of 'ip addr'
ip_output=$(ip addr)

# Initialize variables
current_interface=""
ipv4_addr=""
ipv6_addr=""
declare -A interfaces_with_both_ips
# Read through each line of the ip command output
# Read through each line of the ip command output
while IFS= read -r line; do
    if [[ $line =~ ^[0-9]+: ]]; then
        # New interface section, check the previous interface
        if [[ -n $current_interface && -n $ipv4_addr && -n $ipv6_addr && $current_interface != "lo" ]]; then
            interfaces_with_both_ips["$current_interface"]="IPv4: $ipv4_addr, IPv6: $ipv6_addr"
        fi
        # Reset for the new interface
        current_interface=$(echo $line | awk '{print $2}' | sed 's/:$//')
        ipv4_addr=""
        ipv6_addr=""
    else
        # Check for IPv4 and IPv6 addresses
        if [[ $line =~ inet\  ]]; then
            ipv4_addr=$(echo $line | awk '{print $2}')
        elif [[ $line =~ inet6\  ]]; then
            ipv6_addr=$(echo $line | awk '{print $2}')
        fi
    fi
done <<< "$ip_output"

# Check the last interface
if [[ -n $current_interface && -n $ipv4_addr && -n $ipv6_addr && $current_interface != "lo" ]]; then
    interfaces_with_both_ips["$current_interface"]="IPv4: $ipv4_addr, IPv6: $ipv6_addr"
fi

# Print the matching interfaces and their IP addresses
if [ ${#interfaces_with_both_ips[@]} -ne 0 ]; then
    echo "Interfaces with both IPv4 and IPv6 addresses:"
    for intf in "${!interfaces_with_both_ips[@]}"; do
        echo "$intf: ${interfaces_with_both_ips[$intf]}"
    done
else
    echo "No interfaces found with both IPv4 and IPv6 addresses."
fi
