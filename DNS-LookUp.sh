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

# Check if dig command exists
if ! command -v dig &> /dev/null; then
    echo "dig command could not be found. Please install it (e.g., dnsutils, bind-utils)."
    exit 1
fi

# Timeout setting
TIMEOUT=10

# Arrays to hold results, status, and commands
results=()
statuses=()
commands=()

# Function to read value from config file
get_config_value() {
    local key="$1"
    local value=$(grep "^${key}=" "$config_file" | cut -d'=' -f2- | sed 's/"//g')
    if [ -z "$value" ]; then
        echo "Warning: Key '$key' not found in $config_file or is empty." >&2
    fi
    echo "$value"
}

# Load DNS servers and domain from config file
DNS_SERVER_V4=$(get_config_value "DNS_SERVER_V4")
DNS_SERVER_V6=$(get_config_value "DNS_SERVER_V6")
DOMAIN_TO_LOOKUP=$(get_config_value "DNS_LOOKUP_DOMAIN")

if [ -z "$DNS_SERVER_V4" ] && [ -z "$DNS_SERVER_V6" ]; then
    echo "Error: No DNS servers (DNS_SERVER_V4, DNS_SERVER_V6) defined in $config_file."
    exit 1
fi
if [ -z "$DOMAIN_TO_LOOKUP" ]; then
    echo "Error: No domain (DNS_LOOKUP_DOMAIN) defined in $config_file."
    exit 1
fi

# Function to perform DNS lookup for IPv4 (A record)
test_dnsv4_a() {
    local dns_server=$1
    local domain=$2
    local cmd="dig +timeout=$TIMEOUT +short @$dns_server $domain A"
    echo "Executing: $cmd"
    commands+=("$cmd")
    echo "Performing DNS lookup for IPv4 (A record) of $domain using DNS server $dns_server..."
    local result=$($cmd)
    results+=("IPv4 (A) record result: $result")
    if [[ -n "$result" && ! "$result" =~ "timed out" && ! "$result" =~ "network unreachable" && ! "$result" =~ "no servers could be reached" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to perform DNS lookup for IPv4 (AAAA record)
test_dnsv4_aaaa() {
    local dns_server=$1
    local domain=$2
    local cmd="dig +timeout=$TIMEOUT +short @$dns_server $domain AAAA"
    echo "Executing: $cmd"
    commands+=("$cmd")
    echo "Performing DNS lookup for IPv4 (AAAA record) of $domain using DNS server $dns_server..."
    local result=$($cmd)
    results+=("IPv4 (AAAA) record result: $result")
    if [[ -n "$result" && ! "$result" =~ "timed out" && ! "$result" =~ "network unreachable" && ! "$result" =~ "no servers could be reached" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to perform DNS lookup for IPv6 (AAAA record)
test_dnsv6_aaaa() {
    local dns_server=$1
    local domain=$2
    local cmd="dig +timeout=$TIMEOUT +short @$dns_server $domain AAAA"
    echo "Executing: $cmd"
    commands+=("$cmd")
    echo "Performing DNS lookup for IPv6 (AAAA record) of $domain using DNS server $dns_server..."
    local result=$($cmd)
    results+=("IPv6 (AAAA) record result: $result")
    if [[ -n "$result" && ! "$result" =~ "timed out" && ! "$result" =~ "network unreachable" && ! "$result" =~ "no servers could be reached" ]]; then
        return 0
    else
        return 1
    fi
}

# Tag test status based on the exit code
tag_test_status() {
    local exit_code=$1
    if [ $exit_code -eq 0 ]; then
        if [ -t 1 ]; then # Check if stdout is a terminal
            statuses+=("\033[0;32mTest passed\033[0m") # Green color for passed
        else
            statuses+=("Test passed")
        fi
    else
        if [ -t 1 ]; then # Check if stdout is a terminal
            statuses+=("\033[0;31mTest failed\033[0m") # Red color for failed
        else
            statuses+=("Test failed")
        fi
    fi
}

# Perform DNS lookups and capture results and statuses
if [ -n "$DNS_SERVER_V4" ]; then
    test_dnsv4_a "$DNS_SERVER_V4" "$DOMAIN_TO_LOOKUP"
    tag_test_status $?

    test_dnsv4_aaaa "$DNS_SERVER_V4" "$DOMAIN_TO_LOOKUP"
    tag_test_status $?
else
    echo "Skipping IPv4 DNS tests as DNS_SERVER_V4 is not defined."
fi

if [ -n "$DNS_SERVER_V6" ]; then
    test_dnsv6_aaaa "$DNS_SERVER_V6" "$DOMAIN_TO_LOOKUP"
    tag_test_status $?
fi

# Print detailed results
echo
echo "===== Detailed Results ====="
for result in "${results[@]}"; do
    echo "$result"
done

# Print test statuses
echo
echo "===== Test Statuses ====="
for status in "${statuses[@]}"; do
    echo -e "$status" # Use echo -e to enable interpretation of backslash escapes
done
# Print executed commands
# Print executed commands
echo
echo "===== Executed Commands ====="
for cmd in "${commands[@]}"; do
    echo "$cmd"
done
