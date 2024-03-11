#!/usr/bin/env bash

source ./scripts/util.sh
set -eu

new_account() {
    local node=$1
    local datadir=$2

    # Generate a new account for each geth node
    address=$($GETH_CMD --datadir $datadir account new --password $ROOT/password 2>/dev/null | grep -o "0x[0-9a-fA-F]*")
    echo "Generated an account with address $address for geth node $node and saved it at $datadir"
    echo $address > $datadir/address
}

new_account "'signer'" $SIGNER_EL_DATADIR

# Add the extradata
zeroes() {
    for i in $(seq $1); do
        echo -n "0"
    done
}

address=$(cat $SIGNER_EL_DATADIR/address)

$GETH_CMD init --datadir $SIGNER_EL_DATADIR $GENESIS_FILE 2>/dev/null
echo "Initialized the data directory $SIGNER_EL_DATADIR with $GENESIS_FILE"

# Generate the boot node key
bootnode -genkey $EL_BOOT_KEY_FILE
echo "Generated $EL_BOOT_KEY_FILE"