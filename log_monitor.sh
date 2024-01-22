#!/bin/bash

# Log output function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to load the configuration file
parse_config() {
    local filename="$1"
    local section=""
    declare -gA config
    while read -r line; do
        if [[ "$line" =~ ^\[(.*)\] ]]; then
            section=${BASH_REMATCH[1]}
        elif [[ "$line" =~ ^([A-Za-z0-9_]+)=([^\ ]+.*$) ]]; then
            local key="${section}_${BASH_REMATCH[1]}"
            config[$key]="${BASH_REMATCH[2]}"
        fi
    done < "$filename"
}

# Check if a configuration file is provided as a command-line argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <CONFIG_FILE>"
    exit 1
fi
CONFIG_FILE="$1"

# Load the configuration file
parse_config "$CONFIG_FILE"

# Display loaded settings
echo "Start $0 with:"
echo "Log File: ${config[main_LOGFILE]}"
echo "Cooldown Period: ${config[main_COOLDOWN_PERIOD]}"
echo "Pattern: ${config[main_PATTERN]}"

LOGFILE="${config[main_LOGFILE]}"
COOLDOWN_PERIOD="${config[main_COOLDOWN_PERIOD]}"
PATTERN="${config[main_PATTERN]}"

declare -A last_triggered
declare -A command_scripts

# Load the scripts for each command from the configuration file
for cmd in "${!config[@]}"; do
    if [[ $cmd =~ commands_(.+) ]]; then
        command="${BASH_REMATCH[1]}"
        command_scripts[$command]="${config[$cmd]}"
        last_triggered[$command]=0
    fi
done

# Main loop
tail -Fn0 $LOGFILE | \
while read line ; do
    current_time=$(date +%s)

    if [[ "$line" =~ $PATTERN ]]; then
        command="${BASH_REMATCH[1]}"
        target="${BASH_REMATCH[2]}"

        if [[ -n ${command_scripts[$command]} ]]; then
            if (( current_time - last_triggered[$command] > COOLDOWN_PERIOD )); then
                expanded_command="${command_scripts[$command]//\$target/\"$target\"}"
                command_output=$(eval "$expanded_command")
                log_message "Executed command: $expanded_command"
                log_message "Command output: $command_output"
                last_triggered[$command]=$current_time
            else
                log_message "Skip $command command"
            fi
        else
            log_message "Unknown command: $command"
        fi
    fi
done