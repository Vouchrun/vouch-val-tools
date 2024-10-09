#!/bin/bash

# Function to display the main menu
show_menu() {
    dialog --clear --no-tags --backtitle "Script Runner" \
        --title "Vouch-Val Tool - Main Menu" \
        --no-ok --no-cancel \
        --menu "Select an option:" 20 70 14 \
        "Setup" "" \
        "  1" "Create Key Output Directory" \
        "  2" "Setup Staking Deposit CLI" \
        "  3" "Create Valdiator Keys" \
        "  4" "Backup (zip) All Keystores and Files" \
        "Vouch-Val Tool Commands" "" \
        "  5" "Update vouch-val-tools from repo" \
        "  6" "Exit" 2>menu_choice.txt

    cat menu_choice.txt  # Debugging: Print the contents of menu_choice.txt

    menu_item=$(<menu_choice.txt)
    
    # Debugging output
    echo "Selected menu item: $menu_item"

    case $menu_item in
        "  1") ./helpers/create_inital_working_directories.sh ;;
        "  2") ./helpers/setup_pulse-staking-deposit-cli ;;
        "  3") ./helpers/create_new_keys.sh ;;
        "  4") ./helpers/backup_all_keystores.sh ;;
        "  5") ./helpers/update_vouch_tools.sh ;;
        "  6") clear; exit ;;
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
