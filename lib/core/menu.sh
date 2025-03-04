#!/usr/bin/env bash
# Menu system for user interaction

# Source required dependencies
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# Function to ensure whiptail is installed
function ensure_whiptail_installed() {
    if ! command -v whiptail &>/dev/null; then
        log "INFO" "Installing whiptail for UI..."
        sudo apt-get update -qq &>/dev/null
        sudo apt-get install -y libnewt0.52 &>/dev/null
        
        if ! command -v whiptail &>/dev/null; then
            log "ERROR" "Failed to install whiptail. Please install it manually with: sudo apt-get install libnewt0.52"
            return 1
        fi
    fi
    return 0
}

# Function to show a checkbox menu with whiptail
function show_checkbox_menu() {
    local title=$1
    local -a options=("${!2}")
    local -a funcs=("${!3}")
    local -a recommended=("${!4}")

    # Prepare options array for whiptail
    local num_options=${#options[@]}
    local whiptail_options=()

    # Add regular options with recommended ones pre-selected
    for ((i=0; i<num_options; i++)); do
        local state="OFF"
        if [[ ${recommended[$i]} -eq 1 ]]; then
            state="ON"
        fi
        whiptail_options+=("$i" "${options[$i]}" "$state")
    done

    # Calculate height and width
    local height=$((num_options + 12))
    local width=78

    # Show checkbox dialog
    local selected
    selected=$(whiptail --title "$title" \
              --checklist "Select options (SPACE to toggle, ENTER to confirm):" \
              $height $width $((num_options + 2)) \
              "${whiptail_options[@]}" \
              3>&1 1>&2 2>&3)
    local whiptail_status=$?

    # Exit if cancelled
    if [ $whiptail_status -ne 0 ]; then
        echo "Cancelled"
        return 0  # Return success even when cancelled
    fi

    # Process regular selections - handle whiptail's formatting
    # Remove quotes and process each item
    selected="${selected//\"/}"

    # Process the selection - consider it may be space-separated
    for item in $selected; do
        if [[ $item =~ ^[0-9]+$ ]]; then
            printf "%s\n" "${funcs[$item]}"
        fi
    done

    return 0
}

# Main menu display function
function show_menu() {
    local title=$1
    local options_var=$2
    local funcs_var=$3
    local recommended_var=$4

    # Ensure whiptail is installed
    ensure_whiptail_installed || return 1
    
    # Check if arrays are empty
    local array_size
    eval "array_size=\${#$options_var[@]}"
    
    if [[ $array_size -eq 0 ]]; then
        echo "ERROR: No options to display in menu"
        return 1
    fi
    
    # Show menu with references to the original arrays
    show_checkbox_menu "$title" "$options_var[@]" "$funcs_var[@]" "$recommended_var[@]"
    return $?
}

# Function to show a simple selection menu
function show_selection_menu() {
    local title=$1
    local options_var=$2

    # Ensure whiptail is installed
    ensure_whiptail_installed || return 1

    # Get array size via indirect reference
    local array_size
    eval "array_size=\${#$options_var[@]}"
    
    # Create the menu options array
    local height=$((array_size + 10))
    local width=78
    local menu_options=()

    # Add menu options
    local i=0
    while [ $i -lt $array_size ]; do
        local item
        eval "item=\${$options_var[$i]}"
        menu_options+=("$((i+1))" "$item")
        ((i++))
    done

    # Show the menu
    local selection
    selection=$(whiptail --title "$title" \
                --menu "Please select an option:" \
                $height $width $((array_size + 5)) \
                "${menu_options[@]}" \
                3>&1 1>&2 2>&3)
    local whiptail_status=$?

    if [ $whiptail_status -ne 0 ]; then
        return 1
    fi

    return "$selection"
}

# Function to process menu selections with a callback
function process_menu_selections() {
    local title=$1
    local -n category_config=$2

    # Reinitialize global arrays for menu
    declare -a MENU_DISPLAY_NAMES=()
    declare -a MENU_FUNCTION_NAMES=()
    declare -a MENU_RECOMMENDED=()

    # Fill global arrays with data
    for config_item in "${category_config[@]}"; do
        IFS=':' read -r display_name function_name recommend <<< "$config_item"
        MENU_DISPLAY_NAMES+=("$display_name")
        MENU_FUNCTION_NAMES+=("$function_name")
        MENU_RECOMMENDED+=("$recommend")
    done

    # Get selections from menu
    local selected_functions
    selected_functions=$(show_menu "$title" MENU_DISPLAY_NAMES MENU_FUNCTION_NAMES MENU_RECOMMENDED)
    local menu_status=$?

    # Check if menu was cancelled
    if [[ "$menu_status" -ne 0 || "$selected_functions" == "Cancelled" ]]; then
        return 0  # Return success even when cancelled to avoid script exit
    fi

    # If selections were made, execute callback
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
    else
        log "INFO" "No installation functions to process"
    fi

    return 0
}
