#!/bin/bash

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install jq to proceed."
    exit 1
fi

# Check if expect is installed
if ! command -v expect &> /dev/null; then
    echo "expect is not installed. Please install expect to proceed."
    echo "You can install expect by running: sudo apt install expect"
    exit 1
fi

# Prompt for the client_ID value
read -p "Enter client_ID value: " client_ID

# Prompt the user to select chain (mainnet or testnet)
read -p "Enter 'mainnet' or 'testnet' for the chain: " chain_input

# Set the chain variable based on user input
case $chain_input in
    mainnet)
        chain="pulsechain"
        directory="$HOME/$client_ID/validator_keys/"
        default_password_file_path="$HOME/$client_ID/$client_ID-validator-pw"
        ;;
    testnet)
        chain="pulsechain-testnet-v4"
        directory="$HOME/testnet/$client_ID/validator_keys/"
        default_password_file_path="$HOME/testnet/$client_ID/$client_ID-validator-pw"
        ;;
    *)
        echo "Invalid input. Defaulting to mainnet."
        chain="pulsechain"
        directory="$HOME/$client_ID/validator_keys/"
        default_password_file_path="$HOME/$client_ID/$client_ID-validator-pw"
        ;;
esac

if [[ ! -d "$directory" ]]; then
    echo "Directory '$directory' does not exist. Exiting..."
    exit 1
fi

# Prompt for the voting_keystore_password_path with an option for default value
read -e -p "Enter voting_keystore_password_path (default: $default_password_file_path): " voting_keystore_password_path
voting_keystore_password_path=${voting_keystore_password_path:-"$default_password_file_path"}

# Prompt for the number of validators to exit, default to 100 if not provided
read -p "Enter the number of validators to exit (default: 100): " num_validators
num_validators=${num_validators:-100}

# Ensure num_validators is a valid number
if ! [[ "$num_validators" =~ ^[0-9]+$ ]]; then
    echo "Invalid number of validators. Please enter a valid number."
    exit 1
fi

# Prompt for the starting index value, default to 0 if not provided
read -p "Enter the starting index (default: 0): " starting_index
starting_index=${starting_index:-0}

# Log file setup
log_file="${default_password_file_path%/*}/${client_ID}-validator-exit.log"
exec > >(tee -a "$log_file") 2>&1

# Iterate through each file in the directory matching the pattern
file_count=0
for (( i=$starting_index; i<$(($starting_index + $num_validators)); i++ )); do
    filename="keystore-m_12381_3600_${i}_0_0-*.json"
    files=($directory/$filename)
    if [ ${#files[@]} -eq 0 ]; then
        echo "No files matching $filename found in directory."
    else
        for file in "${files[@]}"; do
            if [ -f "$file" ]; then
                echo "Processing file: $file"

                # Run the docker exec command with the parsed file using expect to provide the exit phrase
                expect <<EOF
log_user 1
set timeout 30
spawn sudo docker exec -it validator lighthouse --network "$chain" account validator exit --beacon-node http://localhost:5052 --password-file "$voting_keystore_password_path" --keystore $file --datadir "/blockchain"
expect {
    "Enter the exit phrase from the above URL to confirm the voluntary exit: " {
        send "Exit my validator\r"
        expect eof
        exit 0  ;# Success
    }
    timeout {
        puts "ERROR: Timeout occurred"
        exit 1  ;# Error
    }
    eof {
        puts "ERROR: Unexpected EOF"
        exit 1  ;# Error
    }
}
EOF

                expect_exit_status=$?
                if [ $expect_exit_status -eq 0 ]; then
                    ((file_count++))
                else
                    echo "Failed to exit validator for file: $file"
                fi
            fi
        done
    fi
done

echo "$file_count validators exited."