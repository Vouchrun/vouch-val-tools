#!/bin/bash

# Function to display the main menu
show_menu() {
    dialog --clear --no-tags --backtitle "Vouch.run" \
        --title "Vouch-Val Tool - Main Menu" \
        --no-ok --no-cancel \
        --menu "Select an option:" 20 70 16 \
        "Setup" "" \
        "  1" "Step.1 - Create Key Output Directory" \
        "  2" "Step.2 - Setup Staking Deposit CLI" \
        "  3" "Step.3 - Create Valdiator Keys" \
        "  4" "Optional - Generate validator_definitions.yml File" \
        "  5" "Optional - Backup (zip) All Keystores and Files" \
        "Validator Operations" "" \
        "  6" "Exit Validators" \
        "Vouch-Val Tool Commands" "" \
        "  7" "Update Vouch-Val-tool" \
        "  8" "Exit" 2>menu_choice.txt

    cat menu_choice.txt  # Debugging: Print the contents of menu_choice.txt

    menu_item=$(<menu_choice.txt)
    
    # Debugging output
    echo "Selected menu item: $menu_item"

    case $menu_item in
        "  1") ./helpers/create_inital_working_directories.sh ;;
        "  2") ./helpers/setup_pulse-staking-deposit-cli.sh ;;
        "  3") ./helpers/create_new_keys.sh ;;
        "  4") ./helpers/generate_validator_definitions_file.sh ;;
        "  5") ./helpers/backup_all_keystores.sh ;;
        "  6") ./helpers/exit_validators.sh ;;
        "  7") ./helpers/update_vouch_tools.sh ;;
        "  8") clear; exit ;;
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

# Ensure jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq could not be found. This script requires jq to run."
    read -p "Would you like to install jq? (Y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        if [ "$(uname)" == "Darwin" ]; then
            brew install jq
        else
            sudo apt-get update
            sudo apt-get install -y jq
        fi
    else
        echo "Exiting script. Please install jq manually to run this script."
        exit
    fi
fi

# Ensure expect is installed
if ! command -v expect &> /dev/null
then
    echo "Expect could not be found. This script requires expect to run."
    read -p "Would you like to install expect? (Y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        if [ "$(uname)" == "Darwin" ]; then
            brew install expect
        else
            sudo apt-get update
            sudo apt-get install -y expect
        fi
    else
        echo "Exiting script. Please install expect manually to run this script."
        exit
    fi
fi

# Loop to display the menu after each action
while true
do
    show_menu
done