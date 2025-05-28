#!/bin/bash

# Exit on error, treat unset variables as an error, and propagate pipeline errors
set -euo pipefail

# Function to display help message
display_help() {
    echo "Usage: $0 -o <log_file> -i <interface> -c <config_file>"
    echo "  -o, --output <log_file>     Specify the output log file name"
    echo "  -i, --interface <interface> Specify the network interface to use for ping"
    echo "  -c, --config <config_file>  Specify the configuration file"
}
# Parse options to set log file name, network interface name, and config file
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -o|--output) log_file="$2"; shift ;;
        -i|--interface) interface="$2"; shift ;;
        -c|--config) config_file="$2"; shift ;;
        *) echo "Unknown option: $1"; display_help; exit 1 ;;
    esac
    shift
done

# If log file name is not specified, display an error message and exit
if [ -z "$log_file" ]; then
    echo "Please specify the output log file name with -o option."
    display_help
    exit 1
fi

# If config file name is not specified, display an error message and exit
if [ -z "$config_file" ]; then
    echo "Please specify the configuration file with -c option."
    display_help
    exit 1
fi

# If network interface is not specified, display an error message and exit
if [ -z "$interface" ]; then
    echo "Please specify the network interface with -i option."
    display_help
    exit 1
fi

# Get start time
start_time=$(date)

# Get the directory of the script itself
SCRIPT_DIR=$(dirname "$0")

# Decoration function
decorate_step() {
    echo "####################################################################"
    echo "# $1"
    echo "####################################################################"
}
# Function to execute sub-script and output to log
execute_and_log() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/$script_name"
    shift 
    local script_args=("$@")

    decorate_step "Executing $script_name..."
    echo "Executing $script_name..." >> "$log_file"
    if [ -x "$script_path" ]; then
        if [ ${#script_args[@]} -gt 0 ]; then
            "$script_path" "${script_args[@]}" 2>&1 | tee -a "$log_file"
        else
            "$script_path" 2>&1 | tee -a "$log_file"
        fi
        if [ $? -eq 0 ]; then
            echo "$script_name completed."
            echo "$script_name completed." >> "$log_file"
        else
            echo "ERROR: $script_name failed." | tee -a "$log_file"
            # Terminate main script on sub-script failure
            echo "Aborting Dropcheck due to error in $script_name." | tee -a "$log_file"
            exit 1
        fi
    else
        echo "ERROR: $script_name not found or not executable at $script_path" | tee -a "$log_file"
        exit 1 # Also terminate if script is not found or not executable
    fi
    echo "" >> "$log_file"
}

# Display start time
decorate_step "Dropcheck started at: $start_time"

# Append script execution result to log file
echo "Dropcheck started at: $start_time" > "$log_file"
echo "" >> "$log_file"

# Execute Pre-Setting
execute_and_log "Initial-Setup.sh" -c "$config_file"

# First Step: Ping test
execute_and_log "Ping-test.sh" -i "$interface" -c "$config_file"

# Second Step: Traceroute
execute_and_log "Traceroute-test.sh" -i "$interface" -c "$config_file"
# Third Step: DNS lookup
execute_and_log "DNS-LookUp.sh" -c "$config_file"

# Fourth Step: HTTP Get
execute_and_log "HTTP-Request-Test.sh" -c "$config_file"
## Fifth Step: Firewall test
execute_and_log "Firewall-Check.sh" -c "$config_file"

# Summary of results
decorate_step "Dropcheck completed."
echo "Dropcheck completed." >> "$log_file"
