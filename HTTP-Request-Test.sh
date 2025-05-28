#!/bin/bash

# Function to display help message
display_help() {
    echo "Usage: $0 -c <config_file>"
    echo "  -c, --config <config_file>  Specify the configuration file"
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

# Check if curl command exists
if ! command -v curl &> /dev/null; then
    echo "curl command could not be found. Please install it."
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

# Load target URLs from config file
TARGET_URL_V4=$(get_config_value "CURL_TARGET_GOOGLE_IPV4")
TARGET_URL_V6=$(get_config_value "CURL_TARGET_GOOGLE_IPV6")

if [ -z "$TARGET_URL_V4" ] && [ -z "$TARGET_URL_V6" ]; then
    echo "Error: No target URLs (CURL_TARGET_GOOGLE_IPV4, CURL_TARGET_GOOGLE_IPV6) defined in $config_file."
    exit 1
fi

# Function to check connectivity
check_connectivity() {
    local url=$1
    local protocol_version_option=$2 # e.g., "-4" or "-6"
    local protocol_display_name=$3   # e.g., "IPv4" or "IPv6"

    if [ -z "$url" ]; then
        echo "URL for $protocol_display_name is not defined in config or is empty. Skipping..."
        return
    fi
    # Ensure all variables used in the echo are correctly defined and passed
    echo "Executing: curl $protocol_version_option -s -o /dev/null -w \"%{http_code}\" --max-time 3 \"$url\""
    local http_code
    http_code=$(curl "$protocol_version_option" -s -o /dev/null -w "%{http_code}" --max-time 3 "$url")

    if [ "$http_code" -eq 200 ]; then
        if [ -t 1 ]; then
            echo -e "\033[0;32mPASS\033[0m: Connection to $url ($protocol_display_name) was successful."
        else
            echo "PASS: Connection to $url ($protocol_display_name) was successful."
        fi
    else
        if [ -t 1 ]; then
            echo -e "\033[0;31mFAIL\033[0m: Connection to $url ($protocol_display_name) failed. HTTP status code: $http_code"
        else
            echo "FAIL: Connection to $url ($protocol_display_name) failed. HTTP status code: $http_code"
        fi
    fi
}

# Check connectivity for IPv4
check_connectivity "$TARGET_URL_V4" "-4" "IPv4"

# Check connectivity for IPv6
check_connectivity "$TARGET_URL_V6" "-6" "IPv6"
