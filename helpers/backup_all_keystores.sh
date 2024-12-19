#!/bin/bash

# Clear the terminal screen
clear

# Define directory paths
source_directory="$HOME/vouch-keys"
destination_directory="$HOME/vouch-keys"

# Check if source directory exists
if [ ! -d "$source_directory" ]; then
    echo "Source directory '$source_directory' does not exist."
    exit 1
fi

# Create zip file with current date and time in the filename
zip_file="$destination_directory/vouch_keystores_$(date +"%Y%m%d_%H%M%S").zip"

# Ask user if they want to encrypt the file
read -p "Do you want to encrypt the file with a password? (yes/no): " encrypt

# Check if user wants to encrypt the file
encrypt=$(echo "${encrypt,,}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

while [ "$encrypt" != "yes" ] && [ "$encrypt" != "no" ] && [ "$encrypt" != "y" ] && [ "$encrypt" != "n" ]; do
    echo "Invalid input. Please enter 'yes' or 'no'."
    read -p "Do you want to encrypt the file with a password? (yes/no): " encrypt
    encrypt=$(echo "${encrypt,,}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
done

if [ "$encrypt" = "yes" ] || [ "$encrypt" = "y" ]; then
    # Prompt user to enter password
    read -s -p "Enter password: " password
    echo ""

    # Prompt user to re-enter password
    read -s -p "Re-enter password: " confirm_password
    echo ""

    # Check if passwords match
    if [ "$password" != "$confirm_password" ]; then
        echo "Error: Passwords do not match."
        exit 1
    fi

    # Check if password is blank
    if [ -z "$password" ]; then
        echo "Error: Password cannot be blank."
        exit 1
    fi

    # Zip the directory with password encryption
    zip -P "$password" -r "$zip_file" "$source_directory"
else
    # Zip the directory without password encryption
    zip -r "$zip_file" "$source_directory"
fi

# Check if zip operation was successful
if [ $? -eq 0 ]; then
    clear
    echo ""
    echo ""
    echo "Directory '$source_directory' zipped successfully."
    echo "Zip file saved as '$zip_file'."
else
    clear
    echo ""
    echo ""
    echo "Error: Failed to zip directory '$source_directory'."
    exit 1
fi



echo ""
read -p "Press Enter to continue..."



exit 0