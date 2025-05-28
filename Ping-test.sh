#!/bin/bash

# Function to display help message
display_help() {
    echo "Usage: $0 -i <interface> -c <config_file>"
    echo "  -i, --interface <interface>   Specify the network interface to use for ping"
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
# 設定ファイルが存在しない場合はエラーメッセージを表示して終了
# If config file does not exist, display an error message and exit
if [ ! -f "$config_file" ]; then
    echo "Configuration file not found: $config_file"
    exit 1
fi

# Function to read value from config file
get_config_value() {
    local key="$1"
    local value=$(grep "^${key}=" "$config_file" | cut -d'=' -f2- | sed 's/"//g')
    echo "$value"
}

# Load target hosts from config file
declare -A TARGETS
TARGETS[google_v4]=$(get_config_value "PING_TARGET_GOOGLE_V4")
TARGETS[google_v6]=$(get_config_value "PING_TARGET_GOOGLE_V6")
TARGETS[CloudFlare_v4]=$(get_config_value "PING_TARGET_CLOUDFLARE_V4")
TARGETS[CloudFlare_v6]=$(get_config_value "PING_TARGET_CLOUDFLARE_V6")
TARGETS[NTTCom_v4]=$(get_config_value "PING_TARGET_NTTCOM_V4")
TARGETS[NTTCom_v6]=$(get_config_value "PING_TARGET_NTTCOM_V6")
TARGETS[KDDI_v4]=$(get_config_value "PING_TARGET_KDDI_V4")
TARGETS[KDDI_v6]=$(get_config_value "PING_TARGET_KDDI_V6")
TARGETS[SoftBank_v4]=$(get_config_value "PING_TARGET_SOFTBANK_V4")
TARGETS[SoftBank_v6]=$(get_config_value "PING_TARGET_SOFTBANK_V6")
TARGETS[mx304_noc_v4]=$(get_config_value "PING_TARGET_MX304_NOC_V4")
TARGETS[mx304_noc_v6]=$(get_config_value "PING_TARGET_MX304_NOC_V6")
TARGETS[ne8000m4_2_noc_v4]=$(get_config_value "PING_TARGET_NE8000M4_2_NOC_V4")
TARGETS[ne8000m4_2_noc_v6]=$(get_config_value "PING_TARGET_NE8000M4_2_NOC_V6")
TARGETS[acx7348_noc_v4]=$(get_config_value "PING_TARGET_ACX7348_NOC_V4")
TARGETS[acx7348_noc_v6]=$(get_config_value "PING_TARGET_ACX7348_NOC_V6")
TARGETS[fx2_noc_v4]=$(get_config_value "PING_TARGET_FX2_NOC_V4")
TARGETS[fx2_noc_v6]=$(get_config_value "PING_TARGET_FX2_NOC_V6")

# Function to print green color text
print_green() {
    if [ -t 1 ]; then # Check if stdout is a terminal
        echo -e "\033[0;32m$1\033[0m"
    else
        echo "$1"
    fi
}

# Function to print red color text
print_red() {
    if [ -t 1 ]; then # Check if stdout is a terminal
        echo -e "\033[0;31m$1\033[0m"
    else
        echo "$1"
    fi
}

# Function to ping a given target
ping_target() {
    local target_v4=$1
    local target_v6=$2
    local result_v4=""
    local result_v6=""

    if [ -n "$target_v4" ]; then
        # Use -W 1 for a 1-second timeout for the entire ping operation for faster failure detection
        local cmd_v4="ping -c 3 -i 0.1 -W 1 -D -I $interface $target_v4"
        echo "Executing: $cmd_v4"
        result_v4=$($cmd_v4 2>&1)
        if [ $? -eq 0 ]; then
            # Ensure result_v4 is not empty before printing, though ping usually outputs something.
            result_v4=$(print_green "$result_v4")
        else
            result_v4=$(print_red "$result_v4")
        fi
    else
        result_v4="IPv4 target is not specified. Skipping..."
    fi
    echo "$result_v4" # Print IPv4 result immediately

    if [ -n "$target_v6" ]; then
        # Use -W 1 for a 1-second timeout for the entire ping operation
        local cmd_v6="ping6 -c 3 -i 0.1 -W 1 -D -I $interface $target_v6"
        echo "Executing: $cmd_v6"
        result_v6=$($cmd_v6 2>&1)
        if [ $? -eq 0 ]; then
            result_v6=$(print_green "$result_v6")
            # Ensure result_v6 is not empty
        else
            result_v6=$(print_red "$result_v6")
        fi
    else
        result_v6="IPv6 target is not specified. Skipping..."
    fi
    echo "$result_v6"
}

# First Step Ping test for GW
echo "============================================================"
echo "====== Starting ping tests for Default Gateway... ======"
echo "============================================================"

# Get the IPv4 default gateway address
PING_TARGET_ADDRESS_IPV4=$(ip route | grep default | awk '{print $3}')
if [ -z "$PING_TARGET_ADDRESS_IPV4" ]; then
    print_red "No IPv4 default gateway found."
else
    print_green "IPv4 Default Gateway: $PING_TARGET_ADDRESS_IPV4"

    # IPv4 Ping tests
    cmd_gw_v4="ping -c 3 -i 0.1 -W 1 -D $PING_TARGET_ADDRESS_IPV4"
    echo "Executing: $cmd_gw_v4"
    $cmd_gw_v4
    cmd_gw_v4_large="ping -c 3 -i 0.1 -W 1 -s 1472 -D $PING_TARGET_ADDRESS_IPV4"
    echo "Executing: $cmd_gw_v4_large"
    $cmd_gw_v4_large
fi

# Get the IPv6 default gateway address
PING_TARGET_ADDRESS_IPV6=$(ip -6 route | grep default | awk '{print $3}')
if [ -z "$PING_TARGET_ADDRESS_IPV6" ]; then
    print_red "No IPv6 default gateway found."
else
    print_green "IPv6 Default Gateway: $PING_TARGET_ADDRESS_IPV6"

    # IPv6 Ping tests
    cmd_gw_v6="ping6 -c 3 -i 0.1 -W 1 -D $PING_TARGET_ADDRESS_IPV6"
    echo "Executing: $cmd_gw_v6"
    $cmd_gw_v6
    cmd_gw_v6_large="ping6 -c 3 -i 0.1 -W 1 -s 1472 -D $PING_TARGET_ADDRESS_IPV6"
    echo "Executing: $cmd_gw_v6_large"
    $cmd_gw_v6_large
fi

echo "============================================================"
echo "====== Finished ping tests for Default Gateway ======"
echo "============================================================"

# List of keys in the desired order
keys=("google" "CloudFlare" "NTTCom" "KDDI" "SoftBank" "mx304_noc" "ne8000m4_2_noc" "acx7348_noc" "fx2_noc")

# Ping tests for each host
for key in "${keys[@]}"; do
    echo "============================================================"
    echo "====== Starting ping tests for $key... ======"
    echo "============================================================"
    ping_target "${TARGETS[${key}_v4]}" "${TARGETS[${key}_v6]}"
    echo "============================================================"
    echo "====== Finished ping tests for $key ======"
    echo "============================================================"
    echo
done
