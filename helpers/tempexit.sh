#!/bin/bash

# WORK IN PROGESS

# Clear the terminal screen
clear

# Prompt to run as Sudo
echo "script needs to be run using root"

if [ "$EUID" -ne 0 ]; then
  sudo "$0" "$@"
  exit $?
fi

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

echo ""
echo ""

# Prompt the user to enter the client_ID
echo "Enter your Graffiti value (used as the key sub-directory path)"
echo ""
echo "NOTE: You can enter a full path later if you customised your key path"
echo ""
read -p "Enter your Graffiti value [default: Vouch.run]: " client_ID
client_ID=${client_ID:-Vouch.run}

# Prompt the user to select chain (mainnet or testnet)
echo ""
while true; do
    read -p "Enter 'mainnet' or 'testnet' for the chain: " chain_input
    case $chain_input in
        mainnet)
            chain="pulsechain"
            default_directory="/blockchain/vouch-keys/$client_ID/validator_keys"
            default_password_file_path="/blockchain/vouch-keys/$client_ID/$client_ID-validator-pw"
            break
            ;;
        testnet)
            chain="pulsechain-testnet-v4"
            default_directory="/blockchain/vouch-keys/testnet/$client_ID/validator_keys"
            default_password_file_path="/blockchain/vouch-keys/testnet/$client_ID/$client_ID-validator-pw"
            break
            ;;
        *)
            read -p "Invalid input. Would you like to retry (R) or exit (E) the script? (R/E): " choice
            case $choice in
                R|r)
                    ;;
                E|e)
                    echo "Exiting script."
                    exit 1
                    ;;
                *)
                    echo "Invalid input. Please enter R to retry or E to exit the script."
                    ;;
            esac
            ;;
    esac
done

# Prompt for the path to the validator keys
echo ""
while true; do
    read -e -p "Enter path to the validator keys (default: $default_directory): " directory
    directory=${directory:-"$default_directory"}
    directory=${directory%/} # Remove trailing slash if present

    if [[ -d "$directory" ]]; then
        break
    else
        echo "Directory '$directory' does not exist."
        read -p "Would you like to Enter [E] the path again or Exit [X] the script? (E/X): " choice
        case $choice in
            E|e)
                ;;
            X|x)
                echo "Exiting script."
                exit 1
                ;;
            *)
                echo "Invalid input. Please enter E to enter the path again or X to exit the script."
                ;;
        esac
    fi
done

# Prompt for the voting_keystore_password_path
echo ""
read -p "Do you have an existing password file for your validator keys (if unsure select No)? (y/n): " has_password_file

if [ "$has_password_file" = "y" ]; then
    password_file_path_set=false
    while [ $password_file_path_set = false ]; do
        read -e -p "Enter full path and file name (default: $default_password_file_path): " voting_keystore_password_path
        voting_keystore_password_path=${voting_keystore_password_path:-"$default_password_file_path"}
        if [ -f "$voting_keystore_password_path" ]; then
            password_file_path_set=true
        else
            echo "The password file '$voting_keystore_password_path' does not exist."
            read -p "Would you like to Enter [E] the path again or Create [C] a new file? (E/C): " choice
            case $choice in
                E|e)
                    continue
                    ;;
                C|c)
                    read -s -p "Enter the password to be written to the file: " password
                    echo -n "$password" > "$voting_keystore_password_path"
                    if [ -f "$voting_keystore_password_path" ]; then
                        password_file_path_set=true
                    else
                        echo "Failed to create password file."
                        exit 1
                    fi
                    ;;
                *)
                    echo "Invalid input. Please enter E to enter the path again or C to create a new file."
                    ;;
            esac
        fi
    done
elif [ "$has_password_file" = "n" ]; then
    read -p "Would you like to Create [C] a new password file or Exit [E]? (C/E): " create_password_file
    case $create_password_file in
        C|c)
            read -e -p "Enter full path and file name (default: $default_password_file_path): " voting_keystore_password_path
            voting_keystore_password_path=${voting_keystore_password_path:-"$default_password_file_path"}
            read -s -p "Enter the password to be written to the file: " password
            echo -n "$password" > "$voting_keystore_password_path"
            if [ -f "$voting_keystore_password_path" ]; then
                :
            else
                echo "Failed to create password file."
                exit 1
            fi
            ;;
        E|e)
            echo "Exiting script."
            exit 1
            ;;
        *)
            echo "Invalid input. Please enter N to create a new file or E to exit."
            exit 1
            ;;
    esac
else
    echo "Invalid input. Please enter y or n."
    exit 1
fi

# Prompt for the number of validators to exit, default to 100 if not provided
echo ""
echo ""
read -p "Enter the number of validators to exit (default: 100): " num_validators
num_validators=${num_validators:-100}

# Ensure num_validators is a valid number
if ! [[ "$num_validators" =~ ^[0-9]+$ ]]; then
    echo "Invalid number of validators. Please enter a valid number."
    exit 1
fi

# Prompt for the starting index value, default to 0 if not provided
echo ""
read -p "Enter the starting index (default: 0): " starting_index
starting_index=${starting_index:-0}

# Log file setup
log_file="$directory${client_ID}-validator-exit.log"
exec > >(tee -a "$log_file") 2>&1

# Iterate through each file in the directory matching the pattern
file_count=0
for (( i=$starting_index; i<$(($starting_index + $num_validators)); i++ )); do
    echo "Processing index $i"
    filename="keystore-m_12381_3600_${i}_0_0-*.json"
    files=("$directory/${filename}")
    if [ ${#files[@]} -eq 0 ]; then
        echo "No files matching $filename found in directory. Files: ${files[@]}"
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

echo "The log file has been output to: $log_file"
read -p "Press Enter to continue..."
