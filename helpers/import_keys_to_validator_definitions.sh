#!/bin/bash

## get Username 
_user="$(id -u -n)"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install jq to proceed."
    exit 1
fi

# Prompt for the client_ID value
read -p "Enter client_ID value: " client_ID

# Prompt the user to select chain (mainnet or testnet)
read -p "Enter 'mainnet' or 'testnet' for the chain: " chain_input

# Set the chain variable based on user input
case $chain_input in
    mainnet)
        directory="$HOME/$client_ID/validator_keys/"
        default_password_file_path="$HOME/$client_ID/$client_ID-validator-pw"
        default_output_path="$HOME/validator_definitions.yml"
        ;;
    testnet)
        directory="$HOME/testnet/$client_ID/validator_keys/"
        default_password_file_path="$HOME/testnet/$client_ID/$client_ID-validator-pw"
        default_output_path="$HOME/validators/validator_definitions.yml"
        ;;
    *)
        echo "Invalid input. Defaulting to mainnet."
        directory="$HOME/$client_ID/validator_keys/"
        default_password_file_path="$HOME/$client_ID/$client_ID-validator-pw"
        default_output_path="$HOME/validator_definitions.yml"
        ;;
esac

# Check if the directory exists
if [ ! -d "$directory" ]; then
  echo "Directory '$directory' does not exist. Creating..."
  mkdir -p "$directory"
  chown -R $_user:vouch "$HOME/"
  chmod -R 770 "$HOME/"
fi

# Set graffiti to client_ID by default
graffiti="$client_ID"

# Prompt for the graffiti value
read -p "Enter graffiti value (default: $client_ID): " user_graffiti
graffiti=${user_graffiti:-"$client_ID"}

# Prompt for the suggested fee recipient value
while true; do
    read -p "Enter suggested fee recipient: " suggested_fee_recipient
    # Check if the provided value is a valid Ethereum address
    if [[ "$suggested_fee_recipient" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
        break
    else
        echo "Invalid Ethereum wallet address. Please enter a valid address."
    fi
done

# Prompt for the enabled value
while true; do
    read -p "Enter 'true' or 'false' for enabled: " enabled
    case $enabled in
        [Tt][Rr][Uu][Ee])
            enabled=true
            break
            ;;
        [Ff][Aa][Ll][Ss][Ee])
            enabled=false
            break
            ;;
        *)
            echo "Please enter 'true' or 'false'."
            ;;
    esac
done

# Check if the user wants to create a new password file
read -p "Do you want to create a new password file? (yes/no, default: no): " create_password_file
create_password_file=${create_password_file:-"no"}  # Set default value to "no"

if [ "$create_password_file" == "yes" ]; then
  # Define the default password file path
  case $chain_input in
      mainnet)
          default_password_file_path="$HOME/$client_ID/$client_ID-validator-pw"
          ;;
      testnet)
          default_password_file_path="$HOME/testnet/$client_ID/$client_ID-validator-pw"
          ;;
  esac

  # Check if the password file already exists
  if [ -f "$default_password_file_path" ]; then
    # Create a backup of the existing password file
    backup_file="${default_password_file_path}.BAK"
    cp "$default_password_file_path" "$backup_file"
    echo "Backup created: $backup_file"
  fi
  
  # Prompt for the keystore password value
  read -s -p "Enter keystore password: " keystore_password
  echo
  
  # Create the new password file with the provided password
  echo "$keystore_password" > "$default_password_file_path"
  echo "Password file created: $default_password_file_path"
  
  # Set owner and group permissions on the password file
  chown $_user:vouch "$default_password_file_path"
  chmod 770 "$default_password_file_path"
fi

# Prompt for the voting_keystore_password_path with an option for default value
read -e -p "Enter voting_keystore_password_path (default: $default_password_file_path): " voting_keystore_password_path
voting_keystore_password_path=${voting_keystore_password_path:-"$default_password_file_path"}

# Prompt for the existing validator_definitions.yml file path
read -e -p "Enter path to existing validator_definitions.yml (default: $default_output_path): " existing_output_path
existing_output_path=${existing_output_path:-"$default_output_path"}

# Check if the file exists
if [ -f "$existing_output_path" ]; then
  # Prompt for the backup creation
  read -p "The file already exists. Do you want to create a backup? (yes/no, default: yes): " create_backup
  create_backup=${create_backup:-"yes"}  # Set default value to "yes"

  if [ "$create_backup" == "yes" ]; then
    # Create the backup file name with date and time
    backup_file="${existing_output_path%.*}_$(date +"%d%m%Y_%H%M%S").yml"
    cp "$existing_output_path" "$backup_file"
    echo "Backup created: $backup_file"
    echo "Backup file path: $backup_file"
  fi
fi

# Insert "---" at the top of the output file if it's a new file
if [ ! -s "$existing_output_path" ]; then
    echo "---" > "$existing_output_path"
fi

# Prompt for the number of keys to import, default to 100 if not provided
read -p "Enter the number of keys to import (default: 100): " num_files
num_files=${num_files:-100}

# Ensure num_files is a valid number
if ! [[ "$num_files" =~ ^[0-9]+$ ]]; then
  echo "Invalid number of files. Please enter a valid number."
  exit 1
fi

# Prompt for the starting index value, default to 0 if not provided
read -p "Enter the starting index (default: 0): " starting_index
starting_index=${starting_index:-0}

# Iterate through each file in the directory matching the pattern
file_count=0
for (( i=$starting_index; i<$(($starting_index + $num_files)); i++ )); do
  filename="keystore-m_12381_3600_${i}_0_0-*.json"
  files=($directory/$filename)
  if [ ${#files[@]} -eq 0 ]; then
    echo "No files matching $filename found in directory."
  else
    for file in "${files[@]}"; do
      if [ -f "$file" ]; then
        echo "Processing file: $file"
        
        # Extract the value for "pubkey" from the JSON file
        pubkey=$(jq -r '.pubkey' "$file")
        
        # Add "0x" to the beginning of the voting_public_key
        pubkey="0x$pubkey"
        
        echo "- enabled: $enabled" >> "$existing_output_path"
        echo "  voting_public_key: \"$pubkey\"" >> "$existing_output_path"
        echo "  graffiti: $graffiti" >> "$existing_output_path"
        echo "  suggested_fee_recipient: \"$suggested_fee_recipient\"" >> "$existing_output_path"
        echo "  type: local_keystore" >> "$existing_output_path"
        echo "  voting_keystore_path: $directory$(basename "$file")" >> "$existing_output_path"
        echo "  voting_keystore_password_path: $voting_keystore_password_path" >> "$existing_output_path"
        
        ((file_count++))
      fi
    done
  fi
done

chown -R $_user:vouch "$HOME/"
chmod -R 770 "$HOME/"

echo "Group and permissions set on folders and files."
echo "Validator definitions added to: $existing_output_path"
