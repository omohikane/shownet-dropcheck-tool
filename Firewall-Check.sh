#!/bin/bash

# Function to display help message
display_help() {
    echo "Usage: $0 -c <config_file>"
    echo "  -c, --config <config_file>  Specify the configuration file"
    echo "  This script will interactively ask for the firewall type to test."
}

# Function to print a message in blue
printb() {
    if [ -t 1 ]; then
        echo -e "\033[1;34m$1\033[0m"
    else
        echo "$1"
    fi
}

# Function to print a message in red
printr() {
    if [ -t 1 ]; then
        echo -e "\033[1;31m$1\033[0m"
    else
        echo "$1"
    fi
}

# Function to print a message in green
printg() {
    if [ -t 1 ]; then
        echo -e "\033[1;32m$1\033[0m"
    else
        echo "$1"
    fi
}

# Function to download file using curl for IPv4
download_file_ipv4() {
    local url=$1
    local result
    result=$(curl -4 --connect-timeout 10 --progress-bar -o /dev/null -w "%{http_code}" "$url")
    echo "$result"
}

# Function to download file using curl for IPv6
download_file_ipv6() {
    local url=$1
    local result
    result=$(curl -6 --connect-timeout 10 --progress-bar -o /dev/null -w "%{http_code}" "$url")
    echo "$result"
}

# Function to check the test status
tag_test_status() {
    local code=$1
    local message=$2
    if [ "$code" -eq 200 ]; then
        printr "FAIL: $message - Firewall Not Running"
    else
        printg "PASS: $message - Firewall Running"
    fi
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

# If config file does not exist, display an error message and exit
if [ ! -f "$config_file" ]; then
    echo "Error: Configuration file not found: $config_file"
    exit 1
fi

# Check if curl is installed
if [[ ! $(which curl) ]]; then
    echo "Please install curl (e.g. sudo apt install curl)."
    exit 1
fi

# Function to read value from config file
get_config_value() {
    local key="$1"
    local value=$(grep "^${key}=" "$config_file" | cut -d'=' -f2- | sed 's/"//g')
    if [ -z "$value" ]; then
        echo "Warning: Key '$key' not found in $config_file or is empty." >&2
    fi
    echo "$value"
}

# STEP 5. Download eicar.txt
printb '#### STEP 5. Firewall check. ####'
# Define firewall options
OPTIONS=(
    'Cisco fpr'
    'Juniper srx'
    'Paloalto pa'
    'Fortinet fg'
)

# Prompt user to select a firewall
echo "Select Firewall list:"
for i in "${!OPTIONS[@]}"; do
    printf "%s) %s\n" "$((i+1))" "${OPTIONS[$i]}"
done

read -p "Enter selection: " selection
# Determine the config key based on selection
# Determine the config key based on selection
selected_option_string="${OPTIONS[$((selection-1))]}"
config_key_suffix=""

case "$selected_option_string" in
    "Cisco fpr")
        config_key_suffix="CISCO_FPR"
        ;;
    "Juniper srx")
        config_key_suffix="JUNIPER_SRX"
        ;;
    "Paloalto pa")
        config_key_suffix="PALOALTO_PA"
        ;;
    "Fortinet fg")
        config_key_suffix="FORTINET_FG"
        ;;
    *)
        echo "Invalid selection."
        exit 1
        ;;
esac

config_key_urls="FIREWALL_URLS_${config_key_suffix}"
comma_separated_urls=$(get_config_value "$config_key_urls")

if [ -z "$comma_separated_urls" ]; then
    echo "Error: URL list for $selected_option_string (key: $config_key_urls) not found or empty in $config_file."
    exit 1
fi

IFS=',' read -r -a DOWNLOAD_FILE_PATHS <<< "$comma_separated_urls"

# Loop through each download file path and test download for IPv4 and IPv6
for current_url in "${DOWNLOAD_FILE_PATHS[@]}"; do
    if [ -z "$current_url" ]; then continue; fi # Skip if a URL is empty (e.g. trailing comma in config)
    printb "Downloading (IPv4): $current_url"
    http_code_ipv4=$(download_file_ipv4 "$current_url")
    echo "Executed command: curl -4 --connect-timeout 10 --progress-bar -o /dev/null -w \"%{http_code}\" \"$current_url\""
    tag_test_status "$http_code_ipv4" "IPv4 download: $current_url"

    printb "Downloading (IPv6): $current_url"
    http_code_ipv6=$(download_file_ipv6 "$current_url")
    echo "Executed command: curl -6 --connect-timeout 10 --progress-bar -o /dev/null -w \"%{http_code}\" \"$current_url\""
    tag_test_status "$http_code_ipv6" "IPv6 download: $current_url"
done
