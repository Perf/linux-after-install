#!/usr/bin/env bash
# UI utilities for interaction and display

# Source required dependencies
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# Colors for output
# Only define if not already set
if [[ -z "${RED:-}" ]]; then RED='\033[0;31m'; fi
if [[ -z "${GREEN:-}" ]]; then GREEN='\033[0;32m'; fi
if [[ -z "${YELLOW:-}" ]]; then YELLOW='\033[1;33m'; fi
if [[ -z "${BLUE:-}" ]]; then BLUE='\033[0;34m'; fi
if [[ -z "${PURPLE:-}" ]]; then PURPLE='\033[0;35m'; fi
if [[ -z "${CYAN:-}" ]]; then CYAN='\033[0;36m'; fi
if [[ -z "${NC:-}" ]]; then NC='\033[0m'; fi # No Color

# Function to show welcome message for installation
function show_welcome_message() {
    clear
    echo "============================================================"
    echo "           Linux System Setup and Installation              "
    echo "============================================================"
    echo ""
    echo "Welcome! This script will help you set up your Linux system."
    echo "It is intended to be run on Kubuntu/KFocus distributions, tested with 24.04 version"
    echo "You can choose from several categories of installations."
    echo ""
}

# Function to print colored messages
function print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to prompt for continue
function prompt_continue() {
    echo ""
    echo "Press Enter to return to the main menu or type 'exit' to quit:"
    read -r response

    if [[ "${response,,}" == "exit" ]]; then
        return 1
    fi

    return 0
}

# Function to print a header
function print_header() {
    local title=$1
    local width=60
    local padding=$(( (width - ${#title}) / 2 ))
    
    echo ""
    echo "$(printf '=%.0s' $(seq 1 $width))"
    echo "$(printf ' %.0s' $(seq 1 $padding))$title"
    echo "$(printf '=%.0s' $(seq 1 $width))"
}

# Function to display operation summary
function display_summary() {
    local title=$1
    local -n items_ref=$2

    clear
    echo "============================================================"
    echo "           $title Summary              "
    echo "============================================================"
    echo ""

    if [[ ${#items_ref[@]} -eq 0 ]]; then
        print_message "$YELLOW" "No items selected."
    else
        print_message "$GREEN" "The following items will be processed:"
        echo ""

        for item in "${items_ref[@]}"; do
            echo "  ✓ $item"
        done
    fi

    echo ""

    if prompt_user "yes_no" "Do you want to proceed?"; then
        return 0
    else
        return 1
    fi
}
