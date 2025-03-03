#!/usr/bin/env bash

# Disable exit on error - we'll handle errors manually
set +e

# Get sudo permissions upfront
sudo echo ""

# Source core libraries
source ./lib/core/utils.sh
source ./lib/core/ui.sh
source ./lib/core/menu.sh

# Source module libraries
source ./lib/installers/template.sh
source ./lib/system/config.sh
source ./lib/system/network.sh
source ./lib/installers/browsers.sh
source ./lib/installers/development.sh
source ./lib/installers/communication.sh
source ./lib/installers/ai_tools.sh
source ./lib/installers/terminal.sh
source ./lib/installers/web3.sh

# Load configuration files
source ./config/system.conf
source ./config/browsers.conf
source ./config/development.conf
source ./config/communication.conf
source ./config/ai_tools.conf
source ./config/terminal.conf
source ./config/web3.conf

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

    # Check if whiptail is available
    if command -v whiptail >/dev/null 2>&1; then
        # Prepare menu options for whiptail
        local menu_options=()
        for i in "${!MAIN_CATEGORIES[@]}"; do
            menu_options+=("$((i+1))" "${MAIN_CATEGORIES[$i]}")
        done

        # Show menu with whiptail using standard redirection
        choice=$(whiptail --title "Linux System Setup and Installation" \
                 --menu "Please select a category to install:" \
                 20 78 12 \
                 "${menu_options[@]}" \
                 3>&1 1>&2 2>&3)
        local whiptail_status=$?
        
        # Handle exit or cancel
        if [ $whiptail_status -ne 0 ]; then
            return 9  # Return the "Exit" option index
        fi
        
        return "$choice"
    else
        # Fallback to pure bash for main menu
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
            echo -n "Enter your choice (1-${#MAIN_CATEGORIES[@]}): "
            read -r choice

            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#MAIN_CATEGORIES[@]}" ]; then
                return "$choice"
            else
                echo "Invalid choice. Press Enter to try again."
                read -r
            fi
        done
    fi
}

# Generic function to process installation selections
function process_installations() {
    local selected_functions=$1
    
    if [[ -n "$selected_functions" ]]; then
        # Log the functions we're about to process
        log "INFO" "Processing installation functions: $selected_functions"
        
        # Read functions line by line to handle spaces in function names
        while read -r func; do
            if [[ -n "$func" ]]; then
                log "INFO" "Running function: $func"
                if declare -F "$func" >/dev/null; then
                    $func || log "ERROR" "Function $func returned an error"
                else
                    log "ERROR" "Function $func does not exist"
                fi
            fi
        done <<< "$selected_functions"
        
        log "INFO" "Finished processing installation functions"
        return 0
    else
        log "INFO" "No installation functions to process"
        return 0
    fi
}

# System Setup Section
function run_system_setup() {
    # Extract arrays from configuration
    declare -a DISPLAY_NAMES=()
    declare -a FUNCTION_NAMES=()
    declare -a RECOMMENDED=()
    
    # Parse configuration
    for config_item in "${SYSTEM_CONFIG[@]}"; do
        IFS=':' read -r display_name function_name recommend <<< "$config_item"
        DISPLAY_NAMES+=("$display_name")
        FUNCTION_NAMES+=("$function_name")
        RECOMMENDED+=("$recommend")
    done
    
    # Show menu and process selections
    echo "Select system configuration options"
    
    # Set the array as globals to ensure they're accessible 
    MENU_DISPLAY_NAMES=("${DISPLAY_NAMES[@]}")
    MENU_FUNCTION_NAMES=("${FUNCTION_NAMES[@]}")
    MENU_RECOMMENDED=("${RECOMMENDED[@]}")
    
    process_menu_selections "System Configuration" MENU_DISPLAY_NAMES MENU_FUNCTION_NAMES MENU_RECOMMENDED process_installations
    
    # Always offer cleanup at the end
    perform_cleanup
}

# Web Browsers & Internet Tools Section
function run_web_browsers_setup() {
    # Extract arrays from configuration
    declare -a DISPLAY_NAMES=()
    declare -a FUNCTION_NAMES=()
    declare -a RECOMMENDED=()
    
    # Parse configuration
    for browser in "${BROWSER_APPS[@]}"; do
        IFS=':' read -r display_name function_name recommend <<< "$browser"
        DISPLAY_NAMES+=("$display_name")
        FUNCTION_NAMES+=("$function_name")
        RECOMMENDED+=("$recommend")
    done
    
    # Show menu and process selections
    echo "Select web browsers and internet tools to install"
    
    # Set the array as globals to ensure they're accessible 
    MENU_DISPLAY_NAMES=("${DISPLAY_NAMES[@]}")
    MENU_FUNCTION_NAMES=("${FUNCTION_NAMES[@]}")
    MENU_RECOMMENDED=("${RECOMMENDED[@]}")
    
    process_menu_selections "Web Browsers & Internet Tools" MENU_DISPLAY_NAMES MENU_FUNCTION_NAMES MENU_RECOMMENDED process_installations
}

# Development Tools Section
function run_development_setup() {
    # Extract arrays from configuration
    declare -a DISPLAY_NAMES=()
    declare -a FUNCTION_NAMES=()
    declare -a RECOMMENDED=()
    
    # Parse configuration
    for dev_tool in "${DEVELOPMENT_APPS[@]}"; do
        IFS=':' read -r display_name function_name recommend <<< "$dev_tool"
        DISPLAY_NAMES+=("$display_name")
        FUNCTION_NAMES+=("$function_name")
        RECOMMENDED+=("$recommend")
    done
    
    # Show menu and process selections
    echo "Select development tools to install"
    
    # Set the array as globals to ensure they're accessible 
    MENU_DISPLAY_NAMES=("${DISPLAY_NAMES[@]}")
    MENU_FUNCTION_NAMES=("${FUNCTION_NAMES[@]}")
    MENU_RECOMMENDED=("${RECOMMENDED[@]}")
    
    process_menu_selections "Development Tools" MENU_DISPLAY_NAMES MENU_FUNCTION_NAMES MENU_RECOMMENDED process_installations
}

# Communication & Collaboration Tools Section
function run_communication_setup() {
    # Extract arrays from configuration
    declare -a DISPLAY_NAMES=()
    declare -a FUNCTION_NAMES=()
    declare -a RECOMMENDED=()
    
    # Parse configuration
    for comm_tool in "${COMMUNICATION_APPS[@]}"; do
        IFS=':' read -r display_name function_name recommend <<< "$comm_tool"
        DISPLAY_NAMES+=("$display_name")
        FUNCTION_NAMES+=("$function_name")
        RECOMMENDED+=("$recommend")
    done
    
    # Show menu and process selections
    echo "Select communication and collaboration tools to install"
    
    # Set the array as globals to ensure they're accessible 
    MENU_DISPLAY_NAMES=("${DISPLAY_NAMES[@]}")
    MENU_FUNCTION_NAMES=("${FUNCTION_NAMES[@]}")
    MENU_RECOMMENDED=("${RECOMMENDED[@]}")
    
    process_menu_selections "Communication & Collaboration Tools" MENU_DISPLAY_NAMES MENU_FUNCTION_NAMES MENU_RECOMMENDED process_installations
}

# AI Tools Section
function run_ai_tools_setup() {
    # Extract arrays from configuration
    declare -a DISPLAY_NAMES=()
    declare -a FUNCTION_NAMES=()
    declare -a RECOMMENDED=()
    
    # Parse configuration
    for ai_tool in "${AI_TOOLS_APPS[@]}"; do
        IFS=':' read -r display_name function_name recommend <<< "$ai_tool"
        DISPLAY_NAMES+=("$display_name")
        FUNCTION_NAMES+=("$function_name")
        RECOMMENDED+=("$recommend")
    done
    
    # Show menu and process selections
    echo "Select AI tools to install"
    
    # Set the array as globals to ensure they're accessible 
    MENU_DISPLAY_NAMES=("${DISPLAY_NAMES[@]}")
    MENU_FUNCTION_NAMES=("${FUNCTION_NAMES[@]}")
    MENU_RECOMMENDED=("${RECOMMENDED[@]}")
    
    process_menu_selections "AI Tools" MENU_DISPLAY_NAMES MENU_FUNCTION_NAMES MENU_RECOMMENDED process_installations
}

# Web 3.0 Tools Section
function run_web3_setup() {
    # Extract arrays from configuration
    declare -a DISPLAY_NAMES=()
    declare -a FUNCTION_NAMES=()
    declare -a RECOMMENDED=()
    
    # Parse configuration
    for web3_tool in "${WEB3_APPS[@]}"; do
        IFS=':' read -r display_name function_name recommend <<< "$web3_tool"
        DISPLAY_NAMES+=("$display_name")
        FUNCTION_NAMES+=("$function_name")
        RECOMMENDED+=("$recommend")
    done
    
    # Show menu and process selections
    echo "Select Web 3.0 tools to install"
    
    # Set the array as globals to ensure they're accessible 
    MENU_DISPLAY_NAMES=("${DISPLAY_NAMES[@]}")
    MENU_FUNCTION_NAMES=("${FUNCTION_NAMES[@]}")
    MENU_RECOMMENDED=("${RECOMMENDED[@]}")
    
    process_menu_selections "Web 3.0 Tools" MENU_DISPLAY_NAMES MENU_FUNCTION_NAMES MENU_RECOMMENDED process_installations
}

# Terminal Customization Section
function run_terminal_setup() {
    # Extract arrays from configuration
    declare -a DISPLAY_NAMES=()
    declare -a FUNCTION_NAMES=()
    declare -a RECOMMENDED=()
    
    # Parse configuration
    for terminal_tool in "${TERMINAL_APPS[@]}"; do
        IFS=':' read -r display_name function_name recommend <<< "$terminal_tool"
        DISPLAY_NAMES+=("$display_name")
        FUNCTION_NAMES+=("$function_name")
        RECOMMENDED+=("$recommend")
    done
    
    # Show menu and process selections
    echo "Select terminal customizations to apply"
    
    # Set the array as globals to ensure they're accessible 
    MENU_DISPLAY_NAMES=("${DISPLAY_NAMES[@]}")
    MENU_FUNCTION_NAMES=("${FUNCTION_NAMES[@]}")
    MENU_RECOMMENDED=("${RECOMMENDED[@]}")
    
    process_menu_selections "Terminal Customization" MENU_DISPLAY_NAMES MENU_FUNCTION_NAMES MENU_RECOMMENDED process_installations
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
