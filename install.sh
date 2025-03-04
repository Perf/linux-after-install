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
echo "       Kubuntu/KFocus System Setup and Installation         "
echo "============================================================"
echo ""
echo "Welcome! This script will help you set up your Kubuntu/KFocus system."
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
    "Cleanup & Exit"
)

function show_main_menu() {
    # Prepare menu options for whiptail
    local menu_options=()
    for i in "${!MAIN_CATEGORIES[@]}"; do
        menu_options+=("$((i+1))" "${MAIN_CATEGORIES[$i]}")
    done

    # Show menu with whiptail using standard redirection
    local choice
    choice=$(whiptail --title "Kubuntu/KFocus System Setup and Installation" \
             --menu "Please select a category to install/process:" \
             20 78 12 \
             "${menu_options[@]}" \
             3>&1 1>&2 2>&3)
    local whiptail_status=$?

    # Handle exit or cancel
    if [ $whiptail_status -ne 0 ]; then
        return 9  # Return the "Exit" option index
    fi

    return "$choice"
}

# Main program
while true; do
    show_main_menu
    choice=$?

    case $choice in
        1)
            _title="System Setup"
            _config_var_name="SYSTEM_CONFIG"
            ;;
        2)
            _title="Web Browsers & Internet Tool"
            _config_var_name="BROWSER_APPS"
            ;;
        3)
            _title="Development Environment"
            _config_var_name="DEVELOPMENT_APPS"
            ;;
        4)
            _title="Communication & Collaboration"
            _config_var_name="COMMUNICATION_APPS"
            ;;
        5)
            _title="AI Tools"
            _config_var_name="AI_TOOLS_APPS"
            ;;
        6)
            _title="Terminal Customization"
            _config_var_name="TERMINAL_APPS"
            ;;
        7)
            _title="Web 3.0"
            _config_var_name="WEB3_APPS"
            ;;
        *)
            perform_cleanup
            echo "Exiting installation script. Goodbye!"
            exit 0
            ;;
    esac

    process_menu_selections "$_title" "$_config_var_name"

    echo ""
    echo "Press Enter to return to the main menu..."
    read -r
done
