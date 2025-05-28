#!/bin/bash

# Function to display help message
display_help() {
    echo "Usage: $0 -i <interface> -c <config_file>"
    echo "  -i, --interface <interface>   Specify the network interface to use for traceroute"
    echo "  -c, --config <config_file>    Specify the configuration file"
}

# Parse options to set network interface name and config file
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--interface) interface="$2"; shift ;;
        -c|--config) config_file="$2"; shift ;;
        *) echo "Unknown option: $1"; display_help; exit 1 ;;
    esac
    shift
done

# If network interface is not specified, display an error message and exit
if [ -z "$interface" ]; then
    echo "Please specify the network interface with -i option."
    display_help
    exit 1
fi

# If config file is not specified, display an error message and exit
if [ -z "$config_file" ]; then
    echo "Please specify the configuration file with -c option."
    display_help
    exit 1
fi

# If config file does not exist, display an error message and exit
if [ ! -f "$config_file" ]; then
    echo "Configuration file not found: $config_file"
    exit 1
fi
# traceroute コマンドの存在チェック
# Check if traceroute command exists
if ! command -v traceroute &> /dev/null; then
    echo "traceroute command could not be found. Please install it."
    exit 1
fi

# Function to read value from config file
get_config_value() {
    local key="$1"
    local value=$(grep "^${key}=" "$config_file" | cut -d'=' -f2- | sed 's/"//g')
    echo "$value"
}

# Define the traceroute options
TRACEROUTE_OPTIONS="-i $interface"

# Load target hosts from config file
declare -A TARGETS
TARGETS[TRACEROUTE_TARGET_GOOGLE_V4]=$(get_config_value "TRACEROUTE_TARGET_GOOGLE_V4")
TARGETS[TRACEROUTE_TARGET_GOOGLE_V6]=$(get_config_value "TRACEROUTE_TARGET_GOOGLE_V6")
# Add more targets here if needed, by defining them in dropcheck.conf and loading them

# Function to perform traceroute
perform_traceroute() {
    local target=$1
    local target_ip=${TARGETS[$target_key]}

    if [ -z "$target_ip" ]; then
        echo "Target IP for $target_key not found in $config_file or is empty. Skipping."
        return
    fi
    
    if [[ "$target_ip" =~ : ]]; then
        echo "============================================================"
        echo "====== Starting traceroute to $target_key ($target_ip - IPv6) ======"
        echo "============================================================"
        local command="sudo traceroute -6 $TRACEROUTE_OPTIONS $target_ip"
        echo "Executing: $command"
        $command
        echo "============================================================"
        echo "====== Finished traceroute to $target (IPv6) ======"
        echo "============================================================"
    else
        echo "============================================================"
        echo "====== Starting traceroute to $target_key ($target_ip - IPv4) ======"
        echo "============================================================"
        local command="sudo traceroute $TRACEROUTE_OPTIONS $target_ip"
        echo "Executing: $command"
        $command
        echo "============================================================"
        echo "====== Finished traceroute to $target (IPv4) ======"
        echo "============================================================"
    fi
}

# Perform traceroute for each target
for target_key_name in "${!TARGETS[@]}"; do
    perform_traceroute "$target_key_name"
done
