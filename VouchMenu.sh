#!/bin/bash

# Function to display the main menu
show_menu() {
    dialog --clear --no-tags --backtitle "Script Runner" \
        --title "Main Menu" \
        --menu "Select an option:" 20 70 14 \
        "Setup" "" \
        "  1" "Create Initial Working Directories" \
        "  2" "Set vouch Permissions" \
        "  3" "Setup Staking Deposit CLI" \
        "  4" "Backup All Keystores" \
        "Key Management" "" \
        "  5" "Create Keys with New Mnemonic" \
        "  6" "Import Keys to Validator Definitions" \
        "  7" "Update Working Validator Definitions File" \
        "Exit Validators" "" \
        "  8" "Exit Validators" \
        "  9" "Exit" 2>menu_choice.txt

    cat menu_choice.txt  # Debugging: Print the contents of menu_choice.txt

    menu_item=$(<menu_choice.txt)
    
    # Debugging output
    echo "Selected menu item: $menu_item"

    case $menu_item in
        "  1") sudo ./helpers/create_inital_working_directories.sh ;;
        "  2") sudo ./helpers/set_vouch_perms.sh ;;
        "  3") sudo ./helpers/setup_pulse-staking-deposit-cli ;;
        "  4") sudo ./helpers/backup_all_keystores.sh ;;
        "  5") sudo ./helpers/create_keys_new_mnemonic.sh ;;
        "  6") sudo ./helpers/import_keys_to_validator_definitions.sh ;;
        "  7") sudo ./helpers/update_working_validator_definitions_file.sh ;;
        "  8") sudo ./helpers/exit_validators.sh ;;
        "  9") clear; exit ;;
        *) echo "Invalid option. Please try again." ;;
    esac
}

# Ensure dialog is installed
if ! command -v dialog &> /dev/null
then
    echo "Dialog could not be found. This script requires dialog to run."
    read -p "Would you like to install dialog? (Y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        if [ "$(uname)" == "Darwin" ]; then
            brew install dialog
        else
            sudo apt-get update
            sudo apt-get install -y dialog
        fi
    else
        echo "Exiting script. Please install dialog manually to run this script."
        exit
    fi
fi

# Loop to display the menu after each action
while true
do
    show_menu
done
