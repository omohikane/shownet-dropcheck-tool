#!/bin/bash

# Exit on error, treat unset variables as an error, and propagate pipeline errors
set -euo pipefail

# Default MTR options
MTR_INTERVAL=0.1
MTR_COUNT=100
DEFAULT_HOSTLIST_FILE="hostlist.txt"
HOSTLIST_FILE="$DEFAULT_HOSTLIST_FILE"

# Function to display help message
display_help() {
    echo "Usage: $0 [-f <hostlist_file>]"
    echo "  Runs MTR for each target specified in the hostlist file."
    echo
    echo "  Options:"
    echo "    -f <hostlist_file>  Specify the hostlist file to use."
    echo "                        (Default: ${DEFAULT_HOSTLIST_FILE})"
    echo "    -h, --help          Display this help message."
    echo
    echo "  Hostlist file format: Each line should be 'name=ip_address'"
    echo "  (e.g., my_server=1.2.3.4 or [\"my_server\"]=\"1.2.3.4\")."
    echo "  Lines starting with '#' and empty lines are ignored."
}

# Parse command-line options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f) HOSTLIST_FILE="$2"; shift ;;
        -h|--help) display_help; exit 0 ;;
        *) echo "Unknown option: $1"; display_help; exit 1 ;;
    esac
    shift
done

# Check if mtr command exists
if ! command -v mtr &> /dev/null; then
    echo "Error: mtr command not found. Please install it."
    exit 1
fi

# Check if hostlist file exists and is readable
if [ ! -f "$HOSTLIST_FILE" ]; then
    echo "Error: Hostlist file '$HOSTLIST_FILE' not found."
    exit 1
elif [ ! -r "$HOSTLIST_FILE" ]; then
    echo "Error: Hostlist file '$HOSTLIST_FILE' is not readable."
    exit 1
fi

echo "Starting MTR tests from hostlist: $HOSTLIST_FILE"
echo "MTR options: Interval=${MTR_INTERVAL}s, Report Cycles=${MTR_COUNT}"
echo "----------------------------------------------------"

line_num=0
# Perform MTR for each target in the hostlist
while IFS= read -r line || [ -n "$line" ]; do # Process last line even if no newline
    line_num=$((line_num + 1))

    # Skip empty lines and comments
    if [[ -z "$line" || "$line" =~ ^\s*# ]]; then
        continue
    fi

    # Parse target name and IP from the line (handles formats like name=ip or ["name"]="ip")
    target_name=$(echo "$line" | awk -F'=' '{print $1}' | tr -d '[]"')
    target_ip=$(echo "$line" | awk -F'=' '{print $2}' | tr -d '[]"')

    if [ -z "$target_name" ] || [ -z "$target_ip" ]; then
        echo "Warning: Skipping malformed line ${line_num} in '$HOSTLIST_FILE': '$line'"
        continue
    fi

    echo # Blank line for readability
    echo "Processing Target: $target_name ($target_ip) (from $HOSTLIST_FILE line $line_num: '$line')"
    echo "----------------------------------------------------"
    if ! sudo mtr --interval "$MTR_INTERVAL" --report-cycles "$MTR_COUNT" "$target_ip"; then
        echo "Warning: MTR command failed for $target_name ($target_ip)"
    fi
    echo "----------------------------------------------------"
done < "$HOSTLIST_FILE"

echo # Blank line
echo "All MTR tests from hostlist '$HOSTLIST_FILE' completed."
