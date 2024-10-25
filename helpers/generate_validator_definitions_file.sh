#!/bin/bash


# Clear the terminal screen
clear

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install jq to proceed."
    exit 1
fi


# Prompt the user to enter the client_ID
echo "Enter the Graffiti value you used to Generate your keys in the previous steps"
read -p "This value will be used to set the import directory [default: Vouch.run]: " client_ID
client_ID=${client_ID:-Vouch.run}

# Prompt the user to select chain (mainnet or testnet)
read -p "Enter 'mainnet' or 'testnet' for the chain [default: mainnet]: " chain_input
chain_input=${chain_input:-mainnet}

# Set the chain variable based on user input
case $chain_input in
    mainnet)
        directory="$HOME/vouch-keys/$client_ID/validator_keys/"
        default_password_file_path="$HOME/vouch-keys/$client_ID/$client_ID-validator-pw"
        default_output_path="$HOME/vouch-keys/$client_ID/validator_definitions.yml"
        suggested_fee_recipient=0x5eAd01d58067a68D0D700374500580eC5C961D0d
        ;;
    testnet)
        directory="$HOME/vouch-keys/testnet/$client_ID/validator_keys/"
        default_password_file_path="$HOME/vouch-keys/testnet/$client_ID/$client_ID-validator-pw"
        default_output_path="$HOME/vouch-keys/testnet/$client_ID/validator_definitions.yml"
        suggested_fee_recipient=0x4C14073Fa77e3028cDdC60bC593A8381119e9921
        ;;
    *)
        echo "Invalid input. Defaulting to testnet."    
        directory="$HOME/vouch-keys/testnet/$client_ID/validator_keys/"
        default_password_file_path="$HOME/vouch-keys/testnet/$client_ID/$client_ID-validator-pw"
        default_output_path="$HOME/vouch-keys/testnet/$client_ID/validator_definitions.yml"
        suggested_fee_recipient=0x4C14073Fa77e3028cDdC60bC593A8381119e9921
        ;;
esac

# Check if the directory exists
if [ ! -d "$directory" ]; then
  echo "Directory '$directory' does not exist. Creating..."
  mkdir -p "$directory"
fi

# Set graffiti to client_ID by default
graffiti="$client_ID"

# Prompt for the graffiti value
echo "Here you can change the publically displayed graffiti for your validators "
read -p "Confirm graffiti value you want to display for Validators (default: $client_ID): " user_graffiti
graffiti=${user_graffiti:-"$client_ID"}

# suggested fee recipient value
echo "Fee recipient will be set to Vouch FeePool address at $suggested_fee_recipient as required."   



# Prompt for the enabled value
echo "We will now set the enabled value for your validators"
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
          default_password_file_path="$HOME/vouch-keys/$client_ID/$client_ID-validator-pw"
          ;;
      testnet)
          default_password_file_path="$HOME/vouch-keys/testnet/$client_ID/$client_ID-validator-pw"
          ;;
  esac

  # Check if the password file already exists
  if [ -f "$default_password_file_path" ]; then
    # Create a backup of the existing password file
    backup_file="${default_password_file_path}.BAK"
    mv "$default_password_file_path" "$backup_file"
    echo ""
    echo "Existing password file detected, backup created at: $backup_file"
  fi
  
  # Prompt for the keystore password value
  read -s -p "Enter keystore password: " keystore_password
  echo
  
  # Create the new password file with the provided password
  echo "$keystore_password" > "$default_password_file_path"
  echo ""
  echo "Password file created: $default_password_file_path"
fi

# Set output path for validator_definitions.yml file
existing_output_path=$default_output_path

# Check if the file exists
if [ -f "$existing_output_path" ]; then
  # Prompt for the backup creation
  echo ""
  echo ""
  echo "A validator_definitions.yml file already exists, these imports will be appended to the existing file."
  read -p "Do you want to create a backup of the existing file as well? (yes/no, default: yes): " create_backup
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

echo ""
echo "Validator definitions added to file at: $existing_output_path"
echo "If you move these keystores to another directory on your validator,"
echo "ensure you edit the keystore and password file paths in the definitions file"


echo "Script completed. Press Y to continue..."
read -p "Continue? (Y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    exit
else
    exit
fi
