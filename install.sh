#!/usr/bin/env bash

set -eu

# Get sudo permissions upfront
sudo echo ""

source ./lib.sh

# Show main welcome message
clear
echo "============================================================"
echo "           Linux System Setup and Installation              "
echo "============================================================"
echo ""
echo "Welcome! This script will help you set up your Linux system."
echo "It is intended to be run on Kubuntu/KFocus distributions, tested with 24.04 version"
echo "You can choose from several categories of installations."
echo ""

# Main menu options
declare -a MAIN_CATEGORIES=(
    "System Setup"
    "Web Browsers & Internet Tools"
    "Development Environment"
    "Communication & Collaboration"
    "AI Tools"
    "Terminal Customization"
    "Web 3.0"
    "All Categories (Complete Setup)"
    "Exit"
)

function show_main_menu() {
    local choice

    # Use pure bash for main menu for simplicity
    while true; do
        clear
        echo "============================================================"
        echo "           Linux System Setup and Installation               "
        echo "============================================================"
        echo ""
        echo "Please select a category to install:"
        echo ""

        for i in "${!MAIN_CATEGORIES[@]}"; do
            printf "%2d) %s\n" $((i+1)) "${MAIN_CATEGORIES[$i]}"
        done

        echo ""
        echo "Enter your choice (1-${#MAIN_CATEGORIES[@]}): "
        read -r choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#MAIN_CATEGORIES[@]}" ]; then
            return "$choice"
        else
            echo "Invalid choice. Press Enter to try again."
            read -r
        fi
    done
}

# System Setup Section
function run_system_setup() {
    # Define system setup options
    declare -a DISPLAY_NAMES=(
        "Remove Snapd"
        "Set System Hostname"
        "Set Swappiness"
        "Add OIBAF Repository"
        "Add Kubuntu Backports Repository"
        "Full System Update"
        "Install Common Utilities"
        "Disable KDE Baloo Indexer"
    )

    # Define function names for system setup
    declare -a FUNCTION_NAMES=(
        "remove_snapd"
        "set_hostname"
        "set_swappiness"
        "add_oibaf_repo"
        "add_kubuntu_backports_repo"
        "perform_system_update"
        "install_common_utilities"
        "disable_kde_baloo"
    )

    # Define recommended options
    declare -a SYSTEM_RECOMMENDED=(
        1 # Remove snapd
        1 # Set hostname
        1 # Set swappiness
        0 # Add OIBAF repo
        0 # Add Kubuntu Backports
        1 # Full system update
        1 # Common utilities
        1 # Disable Baloo
    )

    echo "Select system configuration options"
    selected_system=$(show_installation_menu "System Configuration" DISPLAY_NAMES FUNCTION_NAMES SYSTEM_RECOMMENDED)

    # Check if cancelled
    if [[ "$selected_system" == "Cancelled" ]]; then
        return
    fi

    # Run selected system functions
    if [[ -n "$selected_system" ]]; then
        echo "Applying system configurations..."
        for func in $selected_system; do
            $func
        done
    fi

    # Always offer cleanup at the end
    perform_cleanup
}

# Web Browsers & Internet Tools Section
function run_web_browsers_setup() {
    # Define browser options
    declare -a DISPLAY_NAMES=(
        "Google Chrome"
        "Microsoft Edge"
        "Brave Browser"
        "Transmission Remote GUI"
    )

    # Define function names
    declare -a FUNCTION_NAMES=(
        "install_google_chrome"
        "install_microsoft_edge"
        "install_brave"
        "install_transgui"
    )

    # Define recommended options
    declare -a RECOMMENDED=(
        1 # Google Chrome
        1 # Microsoft Edge
        1 # Brave
        1 # Transmission
    )

    echo "Select web browsers and internet tools to install"
    selected_functions=$(show_installation_menu "Web Browsers & Internet Tools" DISPLAY_NAMES FUNCTION_NAMES RECOMMENDED)

    # Check if cancelled
    if [[ "$selected_functions" == "Cancelled" ]]; then
        return
    fi

    # Run selected installations
    if [[ -n "$selected_functions" ]]; then
        for func in $selected_functions; do
            $func
        done
    fi
}

# Communication & Collaboration Tools Section
function run_communication_setup() {
    # Define communication tools
    declare -a DISPLAY_NAMES=(
        "Slack"
        "Discord"
        "Zoom"
        "AnyDesk"
    )

    # Define function names
    declare -a FUNCTION_NAMES=(
        "install_slack"
        "install_discord"
        "install_zoom"
        "install_anydesk"
    )

    # Define recommended options
    declare -a RECOMMENDED=(
        1 # Slack
        1 # Discord
        1 # Zoom
        1 # AnyDesk
    )

    echo "Select communication and collaboration tools to install"
    selected_functions=$(show_installation_menu "Communication & Collaboration Tools" DISPLAY_NAMES FUNCTION_NAMES RECOMMENDED)

    # Check if cancelled
    if [[ "$selected_functions" == "Cancelled" ]]; then
        return
    fi

    # Run selected installations
    if [[ -n "$selected_functions" ]]; then
        for func in $selected_functions; do
            $func
        done
    fi
}

# AI Tools Section
function run_ai_tools_setup() {
    # Define AI tools
    declare -a DISPLAY_NAMES=(
        "Claude Code"
        "Goose CLI"
        "Windsurf IDE"
        "Cursor IDE"
    )

    # Define function names
    declare -a FUNCTION_NAMES=(
        "install_claude_code"
        "install_goose_cli"
        "install_windsurf_ide"
        "install_cursor_ide"
    )

    # Define recommended options
    declare -a RECOMMENDED=(
        1 # Claude Code
        0 # Goose CLI
        0 # Windsurf IDE
        0 # Cursor IDE
    )

    echo "Select AI tools to install"
    selected_functions=$(show_installation_menu "AI Tools" DISPLAY_NAMES FUNCTION_NAMES RECOMMENDED)

    # Check if cancelled
    if [[ "$selected_functions" == "Cancelled" ]]; then
        return
    fi

    # Run selected installations
    if [[ -n "$selected_functions" ]]; then
        for func in $selected_functions; do
            $func
        done
    fi
}

# Development Tools Section
function run_development_setup() {
    # Define available installations with display names
    declare -a DISPLAY_NAMES=(
        "Visual Studio Code"
        "JetBrains Toolbox"
        "Docker & Docker Compose"
        "Podman CLI & Desktop"
        "Cloud Tools"
        "Ctop (Container Top)"
        "PhpStorm URL Handler"
        "AWS CLI"
        "K8s Lens Desktop"
    )

    # Define function names corresponding to each option
    declare -a FUNCTION_NAMES=(
        "install_vscode"
        "install_jetbrains_toolbox"
        "install_docker_and_docker_compose"
        "install_podman_cli_and_desktop"
        "install_cloud_tools"
        "install_ctop"
        "install_phpstorm_url_handler"
        "install_aws_cli"
        "install_k8s_lens_desktop"
    )

    # Define which options are recommended (1 = recommended, 0 = optional)
    declare -a RECOMMENDED=(
        0 # VS Code
        1 # JetBrains Toolbox
        1 # Docker
        0 # Podman
        0 # Cloud Tools
        1 # Ctop
        1 # PhpStorm URL Handler
        1 # AWS CLI
        1 # K8s Lens
    )

    # Show menu and get selections
    selected_functions=$(show_installation_menu "Development Tools Installation" DISPLAY_NAMES FUNCTION_NAMES RECOMMENDED)

    # Check if the menu was cancelled
    if [[ "$selected_functions" == "Cancelled" ]]; then
        return
    fi

    # Check if any options were selected
    if [[ -z "$selected_functions" ]]; then
        echo "No options selected."
        return
    fi

    # Run selected installations
    for func in $selected_functions; do
        # Execute the function by name
        $func
    done
}

# Web 3.0 Tools Section
function run_web3_setup() {
    # Define available installations with display names
    declare -a DISPLAY_NAMES=(
        "Ledger Live"
        "Ledger Udev Rules"
    )

    # Define function names corresponding to each option
    declare -a FUNCTION_NAMES=(
        "install_ledger_live"
        "install_ledger_udev_rules"
    )

    # Define which options are recommended (1 = recommended, 0 = optional)
    declare -a RECOMMENDED=(
        1 # Ledger Live
        1 # Ledger Udev Rules
    )

    # Show menu and get selections
    selected_functions=$(show_installation_menu "Web3.0 Tools Installation" DISPLAY_NAMES FUNCTION_NAMES RECOMMENDED)

    # Check if the menu was cancelled
    if [[ "$selected_functions" == "Cancelled" ]]; then
        return
    fi

    # Check if any options were selected
    if [[ -z "$selected_functions" ]]; then
        echo "No options selected."
        return
    fi

    # Run selected installations
    for func in $selected_functions; do
        # Execute the function by name
        $func
    done
}

# Terminal Customization Section
function run_terminal_setup() {
    # Define available terminal customizations
    declare -a DISPLAY_NAMES=(
        "Terminal Tools & Utilities"
        "Mononoki Nerd Font"
        "Starship Prompt"
        "All Terminal Customizations"
    )

    # Define function names
    declare -a FUNCTION_NAMES=(
        "install_terminal_tools"
        "install_nerd_fonts"
        "install_starship_prompt"
        "make_terminal_sexy"
    )

    # Define recommended options
    declare -a RECOMMENDED=(
        0 # Terminal Tools
        0 # Nerd Font
        0 # Starship
        1 # All
    )

    # Show menu and get selections
    selected_functions=$(show_installation_menu "Terminal Customization" DISPLAY_NAMES FUNCTION_NAMES RECOMMENDED)

    # Check if the menu was cancelled
    if [[ "$selected_functions" == "Cancelled" ]]; then
        return
    fi

    # Check if any options were selected
    if [[ -z "$selected_functions" ]]; then
        echo "No options selected."
        return
    fi

    # Run selected customizations
    for func in $selected_functions; do
        # Execute the function by name
        $func
    done
}

# Run All Categories
function run_all_setup() {
    echo "Running complete system setup..."

    # Run each category
    run_system_setup
    run_web_browsers_setup
    run_development_setup
    run_communication_setup
    run_ai_tools_setup
    run_terminal_setup
    run_web3_setup

    echo "Complete system setup finished!"
}

# Main program
while true; do
    show_main_menu
    choice=$?

    case $choice in
        1) # System Setup
            run_system_setup
            ;;
        2) # Web Browsers & Internet Tools
            run_web_browsers_setup
            ;;
        3) # Development Environment
            run_development_setup
            ;;
        4) # Communication & Collaboration
            run_communication_setup
            ;;
        5) # AI Tools
            run_ai_tools_setup
            ;;
        6) # Terminal Customization
            run_terminal_setup
            ;;
        7) # Web 3.0
            run_web3_setup
            ;;
        8) # All Categories
            run_all_setup
            ;;
        9) # Exit
            echo "Exiting installation script. Goodbye!"
            exit 0
            ;;
    esac

    echo ""
    echo "Press Enter to return to the main menu..."
    read -r
done
