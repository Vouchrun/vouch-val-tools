#!/bin/bash

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

# Zip the directory
zip -r "$zip_file" "$source_directory"

# Check if zip operation was successful
if [ $? -eq 0 ]; then
    echo "Directory '$source_directory' zipped successfully."
    echo "Zip file saved as '$zip_file'."
else
    echo "Error: Failed to zip directory '$source_directory'."
    exit 1
fi

echo ""
read -p "Press Enter to continue..."



exit 0