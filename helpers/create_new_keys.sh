#!/bin/bash
# create-keys.sh

# Clear the terminal screen
clear

# Check if staking deposit CLI exists
if [ ! -x "$HOME/pulse-staking-deposit-cli/deposit.sh" ]; then
    echo "Error: Staking deposit CLI not found. Please make sure it's installed."
    exit 1
fi

# Prompt the user to select the operation
read -p "Choose an operation: [1] Create Keys Using New Mnemonic Seed [2] Create Keys Using Existing Mnemonic Seed: " option

# Prompt the user to enter the client_ID
read -p "Enter the value for Graffiti (e.g., Vouch): " client_ID

# Prompt the user to select chain (mainnet or testnet)
read -p "Enter 'mainnet' or 'testnet' for the chain: " chain_input

# Set the chain, withdrawal address and FeePool variables based on user input
case $chain_input in
    mainnet)
        chain="pulsechain"
        directory="$HOME/vouch-keys/${client_ID}"
        withdrawal_Address="0x369E33C8782A0CeF14d2e9064598CE991f58000"
        FeePool="0xFEE_POOL"
        ;;
    testnet)
        chain="pulsechain-testnet-v4"
        directory="$HOME/vouch-keys/testnet/${client_ID}"
        withdrawal_Address="0x555E33C8782A0CeF14d2e9064598CE991f58Bc74"
        FeePool="0x4C14073Fa77e3028cDdC60bC593A8381119e9921"
        ;;
    *)
        echo "Invalid input. Defaulting to testnet."
        chain="pulsechain-testnet-v4"
        directory="$HOME/vouch-keys/testnet/${client_ID}"
        withdrawal_Address="0x555E33C8782A0CeF14d2e9064598CE991f58Bc74"
        FeePool="0x4C14073Fa77e3028cDdC60bC593A8381119e9921"
        ;;
esac

# Check if the directory already exists, create it if not
if [ ! -d "$directory" ]; then
  mkdir -p "$directory" || {
    echo "Error: Failed to create directory." >&2
    exit 1
  }
fi

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
    PYTHONPATH=$HOME/pulse-staking-deposit-cli $HOME/pulse-staking-deposit-cli/deposit.sh new-mnemonic \
    --num_validators="${vals_To_Create}" \
    --mnemonic_language=english \
    --chain="${chain}" \
    --folder="$directory" \
    --eth1_withdrawal_address="${withdrawal_Address}"
elif [ $option -eq 2 ]; then
    # Existing mnemonic option
    PYTHONPATH=$HOME/pulse-staking-deposit-cli $HOME/pulse-staking-deposit-cli/deposit.sh existing-mnemonic \
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

# Find the deposit_data file
deposit_data_file=$(find "$directory/validator_keys" -name "deposit_data-*.json")

# Prompt the user to create separate deposit files
read -p "Would you like to create separate deposit files? (y/n): " create_separate_files

if [ "$create_separate_files" = "y" ]; then
    # Parse the deposit data file and create separate deposit files
    jq -c '.[]' "$deposit_data_file" | while read -r deposit_data; do
        echo "$deposit_data" > "$directory/validator_keys/deposit_data-index-$startIndex.json"
        startIndex=$((startIndex + 1))
    done
fi

echo "Keys creation completed successfully."
echo "You MUST set your suggested-fee-recipient correctly to ${FeePool} when running your Validator Client."