#!/usr/bin/env bash
# Menu system for user interaction

# Source required dependencies
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# Function to show a checkbox menu with whiptail
function show_whiptail_menu() {
    local title=$1

    # Get array names
    local options_name=$2
    local funcs_name=$3
    local recommended_name=$4

    local -a options=()
    local -a funcs=()
    local -a recommended=()

    # Use direct array reference if the variable is a local array name
    if [[ "$options_name" == "display_names" ]]; then
        # Use the deserialized arrays directly
        options=("${display_names[@]}")
        funcs=("${function_names[@]}")
        recommended=("${recommended_values[@]}")
    else
        # Get array values using indirection - access array elements by reference
        eval "options=(\"\${$options_name[@]}\")"
        eval "funcs=(\"\${$funcs_name[@]}\")"
        eval "recommended=(\"\${$recommended_name[@]}\")"
    fi

    # Prepare options array for whiptail
    local num_options=${#options[@]}
    local whiptail_options=()

    # Add special options
    whiptail_options+=("ALL" "Select All Options" "OFF")
    whiptail_options+=("RECOMMENDED" "Select Recommended Options" "OFF")
    whiptail_options+=("NONE" "Deselect All Options" "OFF")

    # Add regular options
    for ((i=0; i<num_options; i++)); do
        whiptail_options+=("$i" "${options[$i]}" "OFF")
    done

    # Calculate height and width
    local height=$((num_options + 15))
    local width=78

    # Show checkbox dialog
    local selected

    # Standard whiptail output redirection pattern
    selected=$(whiptail --title "$title" \
              --checklist "Select options (SPACE to toggle, ENTER to confirm):" \
              $height $width $((num_options + 5)) \
              "${whiptail_options[@]}" \
              3>&1 1>&2 2>&3)
    local whiptail_status=$?

    # Exit if cancelled
    if [ $whiptail_status -ne 0 ]; then
        echo "Cancelled"
        return 0  # Return success even when cancelled
    fi


    # Handle special selections
    if [[ $selected == *"ALL"* ]]; then
        # Return all function names
        for ((i=0; i<num_options; i++)); do
            printf "%s\n" "${funcs[$i]}"
        done
        return 0
    elif [[ $selected == *"RECOMMENDED"* ]]; then
        # Return recommended function names
        for ((i=0; i<num_options; i++)); do
            if [[ ${recommended[$i]} -eq 1 ]]; then
                printf "%s\n" "${funcs[$i]}"
            fi
        done
        return 0
    elif [[ $selected == *"NONE"* ]]; then
        # Return nothing
        return 0
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

# Function to show a checkbox menu with pure bash
function show_bash_menu() {
    local title=$1

    # Get array names
    local options_name=$2
    local funcs_name=$3
    local recommended_name=$4

    local -a options=()
    local -a funcs=()
    local -a recommended=()

    # Use direct array reference if the variable is a local array name
    if [[ "$options_name" == "display_names" ]]; then
        # Use the deserialized arrays directly
        options=("${display_names[@]}")
        funcs=("${function_names[@]}")
        recommended=("${recommended_values[@]}")
    else
        # Get array values using indirection - access array elements by reference
        eval "options=(\"\${$options_name[@]}\")"
        eval "funcs=(\"\${$funcs_name[@]}\")"
        eval "recommended=(\"\${$recommended_name[@]}\")"
    fi

    local num_options=${#options[@]}
    local selected=()

    # Initialize all as unselected
    for ((i=0; i<num_options; i++)); do
        selected[$i]=0
    done

    while true; do
        clear
        echo "================================================================================"
        echo "                            $title"
        echo "================================================================================"
        echo ""
        echo "Select options (enter numbers to toggle, then press ENTER when done):"
        echo ""

        # Special options
        echo "Special options:"
        echo "  A) [ ] Select All"
        echo "  R) [ ] Select Recommended"
        echo "  N) [ ] Deselect All"
        echo ""

        # Regular options
        echo "Options:"
        for ((i=0; i<num_options; i++)); do
            local checkbox="[ ]"
            local recommend=""

            if [[ ${selected[$i]} -eq 1 ]]; then
                checkbox="[x]"
            fi

            if [[ ${recommended[$i]} -eq 1 ]]; then
                recommend=" (recommended)"
            fi

            printf "  %2d) %s %s%s\n" $((i+1)) "$checkbox" "${options[$i]}" "$recommend"
        done

        echo ""
        echo "Enter your selection (numbers, A, R, N, or 'done' to proceed): "
        read -r selection

        # Handle special inputs
        if [[ "${selection,,}" == "a" ]]; then
            # Select all
            for ((i=0; i<num_options; i++)); do
                selected[$i]=1
            done
        elif [[ "${selection,,}" == "r" ]]; then
            # Select recommended
            for ((i=0; i<num_options; i++)); do
                if [[ ${recommended[$i]} -eq 1 ]]; then
                    selected[$i]=1
                else
                    selected[$i]=0
                fi
            done
        elif [[ "${selection,,}" == "n" ]]; then
            # Deselect all
            for ((i=0; i<num_options; i++)); do
                selected[$i]=0
            done
        elif [[ "${selection,,}" == "done" || -z "$selection" ]]; then
            # Confirm selection
            break
        else
            # Toggle individual selections
            IFS=',' read -ra indices <<< "$selection"
            for index in "${indices[@]}"; do
                if [[ "$index" =~ ^[0-9]+$ ]]; then
                    idx=$((index-1))
                    if [[ $idx -ge 0 && $idx -lt num_options ]]; then
                        selected[$idx]=$((1-selected[$idx]))  # Toggle
                    fi
                fi
            done
        fi
    done

    # Return selected function names
    for ((i=0; i<num_options; i++)); do
        if [[ ${selected[$i]} -eq 1 ]]; then
            echo "${funcs[$i]}"
        fi
    done

    return 0
}

# Function to deserialize a serialized array
function deserialize_array() {
    local serialized_string=$1
    local is_base64=$2

    # Split the string by the separator and process each item
    IFS=';' read -ra parts <<< "$serialized_string"

    # Print each item on a separate line to be read by readarray
    for part in "${parts[@]}"; do
        if [[ -n "$part" ]]; then
            if [[ "$is_base64" == "1" ]]; then
                echo "$(echo "$part" | base64 --decode)"
            else
                echo "$part"
            fi
        fi
    done
}

# Main menu display function with fallback
function show_menu() {
    local title=$1
    local options_name=$2
    local funcs_name=$3
    local recommended_name=$4


    # Check if arrays are empty
    local array_size=0
    eval "array_size=\${#$options_name[@]}"

    if [[ $array_size -eq 0 ]]; then
        echo "ERROR: No options to display in menu"
        return 1
    fi

    # Check if we are using serialized environment variables
    if [[ "$options_name" == "MENU_DISPLAY_NAMES" && -n "$MENU_ITEMS_COUNT" ]]; then
        # Deserialize the arrays
        local -a display_names
        local -a function_names
        local -a recommended_values

        # Read serialized strings into arrays
        readarray -t display_names < <(deserialize_array "$MENU_DISPLAY_NAMES" 1)
        readarray -t function_names < <(deserialize_array "$MENU_FUNCTION_NAMES" 0)
        readarray -t recommended_values < <(deserialize_array "$MENU_RECOMMENDED" 0)

        # Override options_name, funcs_name, and recommended_name with local arrays
        options_name="display_names"
        funcs_name="function_names"
        recommended_name="recommended_values"
    fi


    # Check if whiptail is available
    if command -v whiptail >/dev/null 2>&1; then
        # Use whiptail
        show_whiptail_menu "$title" "$options_name" "$funcs_name" "$recommended_name"
        return $?
    else
        # Offer to install whiptail
        echo "The 'whiptail' package is not installed. It provides a better interface for selections."
        echo "Would you like to install it now? (y/n)"
        read -r install_whiptail

        if [[ "${install_whiptail,,}" == "y"* ]]; then
            log "INFO" "Installing whiptail for improved UI"
            (
                sudo apt-get update -qq >/dev/null 2>&1
                sudo apt-get install -y libnewt0.52 >/dev/null 2>&1
            ) & show_progress $! "Installing whiptail"

            # Now try whiptail again
            if command -v whiptail >/dev/null 2>&1; then
                show_whiptail_menu "$title" "$options_name" "$funcs_name" "$recommended_name"
                return $?
            else
                log "WARN" "Failed to install whiptail, using fallback UI"
            fi
        fi

        # Fallback to bash UI
        show_bash_menu "$title" "$options_name" "$funcs_name" "$recommended_name"
        return $?
    fi
}

# Function to show a simple selection menu
function show_selection_menu() {
    local title=$1
    local -n options_ref=$2

    while true; do
        clear
        echo "============================================================"
        echo "           $title"
        echo "============================================================"
        echo ""
        echo "Please select an option:"
        echo ""

        for i in "${!options_ref[@]}"; do
            printf "%2d) %s\n" $((i+1)) "${options_ref[$i]}"
        done

        echo ""
        echo "Enter your choice (1-${#options_ref[@]}): "
        read -r choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options_ref[@]}" ]; then
            return "$choice"
        else
            echo "Invalid choice. Press Enter to try again."
            read -r
        fi
    done
}

# Function to process menu selections with a callback
function process_menu_selections() {
    local title=$1
    local options_name=$2
    local funcs_name=$3
    local recommended_name=$4
    local callback=$5

    # Get selections from menu
    local selected_functions

    # Simplify by using command substitution directly
    selected_functions=$(show_menu "$title" "$options_name" "$funcs_name" "$recommended_name")
    local menu_status=$?

    # Check if menu was cancelled
    if [[ "$menu_status" -ne 0 || "$selected_functions" == "Cancelled" ]]; then
        return 0  # Return success even when cancelled to avoid script exit
    fi

    # If selections were made, execute callback
    if [[ -n "$selected_functions" ]]; then
        $callback "$selected_functions"
    fi

    return 0
}
