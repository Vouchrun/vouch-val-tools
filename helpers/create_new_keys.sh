#!/bin/bash
# create-keys.sh

# Check if staking deposit CLI exists
if [ ! -x "$HOME/staking-deposit-cli/deposit.sh" ]; then
    echo "Error: Staking deposit CLI not found. Please make sure it's installed."
    exit 1
fi

# Navigate to the directory where the staking deposit CLI is located
cd $HOME/staking-deposit-cli || exit 1

# Prompt the user to select the operation
read -p "Choose an operation: [1] Create Keys Using New Mnemonic Seed [2] Create Keys Using Existing Mnemonic Seed: " option

# Prompt the user to enter the client_ID
read -p "Enter the value for client_ID (e.g., bk00001): " client_ID

# Prompt the user to select chain (mainnet or testnet)
read -p "Enter 'mainnet' or 'testnet' for the chain: " chain_input

# Set the chain variable based on user input
case $chain_input in
    mainnet)
        chain="pulsechain"
        directory="$HOME/${client_ID}"
        ;;
    testnet)
        chain="pulsechain-testnet-v4"
        directory="$HOME/testnet/${client_ID}"
        ;;
    *)
        echo "Invalid input. Defaulting to testnet."
        chain="pulsechain-testnet-v4"
        directory="$HOME/testnet/${client_ID}"
        ;;
esac

# Check if the directory already exists, create it if not
if [ ! -d "$directory" ]; then
  mkdir -p "$directory" || {
    echo "Error: Failed to create directory." >&2
    exit 1
  }
fi

# Prompt the user to enter the withdrawal_Address
read -p "Enter the value for the Withdrawal Address: " withdrawal_Address

# Prompt the user to enter the number of validators to create
read -p "How many validators would you like to create (default: 50): " vals_To_Create
vals_To_Create=${vals_To_Create:-50}

# Prompt the user for the start index (only for existing mnemonic option)
startIndex=${startIndex:-0}
case $option in
    2)
        read -p "Enter the start index for the validators: " startIndex
        ;;
esac

# Run the deposit.sh script with the specified parameters
if [ $option -eq 1 ]; then
    # New mnemonic option
    ./deposit.sh new-mnemonic \
    --num_validators="${vals_To_Create}" \
    --mnemonic_language=english \
    --chain="${chain}" \
    --folder="$directory" \
    --eth1_withdrawal_address="${withdrawal_Address}"
elif [ $option -eq 2 ]; then
    # Existing mnemonic option
    ./deposit.sh existing-mnemonic \
    --num_validators="${vals_To_Create}" \
    --validator_start_index="$startIndex" \
    --chain="${chain}" \
    --folder="$directory" \
    --eth1_withdrawal_address="${withdrawal_Address}"
else
    echo "Invalid option. Please choose 1 or 2."
    exit 1
fi

# Check if the deposit.sh command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to execute deposit.sh script."
    exit 1
fi

echo "Keys creation completed successfully."