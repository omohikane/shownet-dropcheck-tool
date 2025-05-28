#!/bin/bash

# Function to display help message
display_help() {
    echo "Usage: $0 -i <interface>"
    echo "  -i, --interface <interface>   Specify the network interface to use for traceroute"
}
# Parse options to set network interface name
output_file="tmp_traceroute.txt"
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--interface) interface="$2"; shift ;;
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

# Define the traceroute options
TRACEROUTE_OPTIONS="-i $interface"

# Define the target hosts
declare -A TARGETS=(
    [GOOGLE_PUBLIC_DNS_V4]='8.8.8.8'
    [GOOGLE_PUBLIC_DNS_V6]='2001:4860:4860::8888'
)
# Function to perform traceroute and save results to file
# Function to perform traceroute and save results to file
perform_traceroute() {
    local target=$1
    local target_ip=${TARGETS[$target]}
    if [ -z "$target_ip" ]; then
        echo "Target $target not found."
        return
    fi

    echo "============================================================"
    echo "====== Starting traceroute to $target ======"
    echo "============================================================"
    echo "============================================================" >> "$output_file"
    echo "====== Starting traceroute to $target ======" >> "$output_file"
    echo "============================================================" >> "$output_file"
    if [[ "$target_ip" =~ : ]]; then
        sudo traceroute -6 $TRACEROUTE_OPTIONS $target_ip | tee -a "$output_file"
    else
        sudo traceroute $TRACEROUTE_OPTIONS $target_ip | tee -a "$output_file"
    fi
    echo "============================================================"
    echo "====== Finished traceroute to $target ======"
    echo "============================================================"
    echo "============================================================" >> "$output_file"
    echo "====== Finished traceroute to $target ======" >> "$output_file"
    echo "============================================================" >> "$output_file"
}

# Perform traceroute for each target
for target in "${!TARGETS[@]}"; do
    perform_traceroute $target
done

echo "Traceroute results saved to $output_file"
# Define the function to convert IP addresses to hostnames
# Define the function to convert IP addresses to hostnames
convert_ip_to_hostname() {
    local ip=$1
    local hostname=$(grep -F "$ip" hostlist.txt | awk '{print $1}')
    if [ -z "$hostname" ]; then
        echo "$ip"
    else
        echo "$hostname"
    fi
}
# Read the traceroute result file and convert IP addresses to hostnames
# Read the traceroute result file and convert IP addresses to hostnames
while IFS= read -r line; do
    # Extract the IP address from the line
    ip=$(echo "$line" | awk '{print $(NF-1)}')
    # Convert the IP address to a hostname
    hostname=$(convert_ip_to_hostname "$ip")
    # Print the line with the hostname
    echo "$line" | sed "s/$ip/$hostname/"
done < tmp_traceroute.txt
