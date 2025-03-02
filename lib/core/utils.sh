#!/usr/bin/env bash
# Core utility functions for system operations

# Set error handling by default
set -eu

# Helper function for logging
function log() {
    local level=$1
    local message=$2
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    printf "[%b] [%b] %b\n" "$timestamp" "$level" "$message" >&2
}

# Helper function for showing progress
function show_progress() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % ${#spin} ))
        printf "\r[%b] %b..." "${spin:$i:1}" "$message"
        sleep 0.1
    done
    printf "\r✓ %b...done\n" "$message"
}

# Helper function for user prompt
function prompt_user() {
    local prompt_type="${1}"    # yes_no, choice, or input
    local message="${2}"
    local default="${3:-}"
    local options="${4:-}"      # For choice type

    # Display formatted message with visual separator
    printf "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    printf "🔹 %b\n" "$message"

    case "$prompt_type" in
        "yes_no")
            printf "[Y/n]: "
            read -r answer
            [[ -z "$answer" || "${answer,,}" == "y"* ]] && return 0 || return 1
            ;;
        "choice")
            IFS=',' read -ra choices <<< "$options"
            for i in "${!choices[@]}"; do
                printf "%d) %b\n" $((i+1)) "${choices[$i]}"
            done
            printf "Choose [1-%d]: " "${#choices[@]}"
            read -r REPLY
            printf "%b" "$REPLY"
            ;;
        "input")
            if [[ -n "$default" ]]; then
                printf "[default: %s]: " "$default"
            else
                printf ": "
            fi
            read -r input
            REPLY="${input:-$default}"
            printf "%s" "$REPLY"
            ;;
    esac
}

# Function to perform system cleanup
function perform_cleanup() {
    log "INFO" "Starting system cleanup"
    
    if prompt_user "yes_no" "Would you like to clean up package caches and remove unused packages?"; then
        (
            sudo apt -y autoclean > /dev/null 2>&1
            sudo apt -y autoremove > /dev/null 2>&1
        ) & show_progress $! "Cleaning up system"
        log "INFO" "System cleanup completed successfully"
    else
        log "INFO" "System cleanup skipped"
    fi
}