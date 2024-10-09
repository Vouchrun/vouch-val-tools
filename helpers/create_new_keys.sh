#!/bin/bash
# create-keys.sh

# Clear the terminal screen
clear

# Check if staking deposit CLI exists
if [ ! -x "$HOME/pulse-staking-deposit-cli/deposit.sh" ]; then
    echo "Error: Staking deposit CLI not found. Please make sure it's installed."
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install jq to proceed."
    echo "Running "Setup Staking Deposit CLI" from the menu will do this ."
    exit 1
fi

# Navigate to the directory where the staking deposit CLI is located
cd $HOME/pulse-staking-deposit-cli || exit 1

# Prompt the user to select the operation
read -p "Create Keys Using: [1] New Mnemonic Seed [2] Existing Mnemonic Seed: " option

# Prompt the user to enter the client_ID
read -p "Enter the value for Graffiti (e.g., Vouch) [default: Vouch.run]: " client_ID
client_ID=${client_ID:-Vouch.run}

# Prompt the user to select chain (mainnet or testnet)
read -p "Enter 'mainnet' or 'testnet' for the chain [default: mainnet]: " chain_input
chain_input=${chain_input:-mainnet}

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
read -p "How many validators would you like to create (default: 10): " vals_To_Create
vals_To_Create=${vals_To_Create:-10}

# Clear the terminal screen
clear

echo "README"
echo ""
echo "NOTE 1: - Setting Withdrawal Address"
echo "In the next step you will be asked about your withdrawal address"
echo "it is critical that you use the Vouch withdrawal contract address,"
echo "this address will be auto-filled based on the network you select"
echo "make sure to copy and paste the Vouch withdrawal contact adderess"
echo "when prompted to do so."
echo ""
echo "NOTE 2: -  Entering Deposit Amount"
echo "You will also be prompted for the validator deposit amount"
echo "this needs to be 12000000 (12Mil Pulse) for a solo validator."
echo "Use the correct amount so your deposit will be successful"





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
echo ""
echo ""
echo "OPTIONAL - Generate Multiple Deposit and Stake Files"
echo ""
echo "If you would like to have more control over the deposit and staking"
echo "process you can have this tool create a deposit and staking file"
echo "for each of your validator keys."
echo ""
echo ""
read -p "Would you also like to create separate deposit and stake files for each validator index? (y/n): " create_separate_files

if [ "$create_separate_files" = "y" ]; then
    # Parse the deposit data file and create separate deposit files
    index=$startIndex
    jq -c '.[]' "$deposit_data_file" | while read -r deposit_data; do
        echo "[$deposit_data]" > "$directory/validator_keys/deposit_data-index-$index.json"
        index=$((index + 1))
        if [ $((index - startIndex)) -ge $vals_To_Create ]; then
            break
        fi
    done

    # Find the stake_data file
    stake_data_file=$(find "$directory/validator_keys" -name "stake_data-*.json")

    # Parse the stake data file and create separate stake files
    index=$startIndex
    jq -c '.[]' "$stake_data_file" | while read -r stake_data; do
        echo "[$stake_data]" > "$directory/validator_keys/stake_data-index-$index.json"
        index=$((index + 1))
        if [ $((index - startIndex)) -ge $vals_To_Create ]; then
            break
        fi
    done
fi

echo "Your Keys creation completed successfully."
echo ""
echo ""
echo ""
echo ""
echo "IMPORTANT READ THIS"
echo ""
echo "1. You MUST set your suggested-fee-recipient correctly to ${FeePool} when running your Validator Client."
echo ""
echo "2. Your deposit and staking files are located with your new Keys. "
echo "For more informattion on using these files go to https://vouch.run"
echo ""
echo ""
echo ""