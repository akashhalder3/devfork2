#!/usr/bin/env bash

source ./scripts/util.sh
set -eu

mkdir -p $CONSENSUS_DIR

if ! test -e ./web3/node_modules; then
    echo "The package ./web3 doesn't have node modules installed yet. Installing the node modules now"
    npm --prefix ./web3 install >/dev/null 2>/dev/null
    echo "Node modules are already installed"
fi

# Use the signing node as a node to deploy the deposit contract
# output=$(NODE_PATH=./web3/node_modules node ./web3/src/deploy-deposit-contract.js --endpoint $SIGNER_EL_DATADIR/geth.ipc)
address="0x23DDc2B6A523e3497a44299E7026d347b12B83B0"
transaction=""
block_number="3"

# echo "Deployed the deposit contract of the address $address in the transaction $transaction on the block number $block_number"

echo $address > $ROOT/deposit-address
echo $block_number > $CONSENSUS_DIR/deploy_block.txt

# Select the validator
mkdir -p $CONSENSUS_DIR/validator_keys
NODE_PATH=./web3/node_modules node ./web3/src/distribute-validators.js \
    --nc $NODE_COUNT \
    --vc $VALIDATOR_COUNT \
    -d $BUILD_DIR/validator_keys \
    -o $CONSENSUS_DIR/validator_keys \
    > $ROOT/deposit-data.json

echo "Sending the deposits to the deposit contract"
NODE_PATH=./web3/node_modules node ./web3/src/transfer-deposit.js \
    --endpoint http://20.40.53.142:8000 \
    --deposit-address $address \
    -f $ROOT/deposit-data.json
echo -e "\nDone sending all the deposits to the contract"

cp /home/azureuser/devfork2/consensus/config.yaml $CONFIG_FILE
cp /home/azureuser/devfork2/consensus/genesis.ssz /home/azureuser/devfork2/data/consensus
PRESET_BASE=mainnet
echo $PRESET_BASE
# echo "TERMINAL_TOTAL_DIFFICULTY: \"$TERMINAL_TOTAL_DIFFICULTY\"" >> $CONFIG_FILE
# echo "MIN_GENESIS_ACTIVE_VALIDATOR_COUNT: \"$VALIDATOR_COUNT\"" >> $CONFIG_FILE
# echo "MIN_GENESIS_TIME: \"$(expr $(date +%s) + $GENESIS_DELAY)\"" >> $CONFIG_FILE
# echo "GENESIS_DELAY: \"$GENESIS_DELAY\"" >> $CONFIG_FILE
# echo "GENESIS_FORK_VERSION: \"$GENESIS_FORK_VERSION\"" >> $CONFIG_FILE

# echo "DEPOSIT_CHAIN_ID: \"$NETWORK_ID\"" >> $CONFIG_FILE
# echo "DEPOSIT_NETWORK_ID: \"$NETWORK_ID\"" >> $CONFIG_FILE
# echo "DEPOSIT_CONTRACT_ADDRESS: \"$address\"" >> $CONFIG_FILE

# echo "SECONDS_PER_SLOT: \"$SECONDS_PER_SLOT\"" >> $CONFIG_FILE
# echo "SECONDS_PER_ETH1_BLOCK: \"$SECONDS_PER_ETH1_BLOCK\"" >> $CONFIG_FILE

# echo "Generated $CONFIG_FILE"

# lcli eth1-genesis \
#     --spec $PRESET_BASE \
#     --eth1-endpoints http://0.0.0.0:$SIGNER_HTTP_PORT \
#     --testnet-dir $CONSENSUS_DIR 2>/dev/null

# echo "Generated $CONSENSUS_DIR/genesis.ssz"

# lcli \
# 	generate-bootnode-enr \
# 	--ip 20.40.53.142 \
# 	--udp-port $CL_BOOTNODE_PORT \
# 	--tcp-port $CL_BOOTNODE_PORT \
# 	--genesis-fork-version $GENESIS_FORK_VERSION \
# 	--output-dir $CL_BOOTNODE_DIR

bootnode_enr=enr:-My4QJ9nGxXDZ3St-iHJNwq0mIo5G4cYbFKlbNRF0YJM9M0McGdD07aJgkkBu5Ucjz_jhqZSSywcPqrT1pvaDoslb74Bh2F0dG5ldHOIAAAAAAAAAACEZXRoMpB6zWmpcAAAaf__________gmlkgnY0gmlwhBQoNY6EcXVpY4IjKYlzZWNwMjU2azGhAsVAQyIZoSG8X_yWRoAk5FfLWfuEQFL-rLgWLfzQbTceiHN5bmNuZXRzAIN0Y3CCIyiEdGNwNoIPq4N1ZHCCD6s
echo "- $bootnode_enr" > $CONSENSUS_DIR/boot_enr.yaml
echo "Generated $CONSENSUS_DIR/boot_enr.yaml"

echo "Importing the keystores of the validators to the lighthouse data directories"
for (( node=1; node<=$NODE_COUNT; node++ )); do
    cl_data_dir $node
    el_data_dir $node
    mkdir -p $cl_data_dir
    cp $el_data_dir/geth/jwtsecret $cl_data_dir
    $LIGHTHOUSE_CMD \
        --testnet-dir $CONSENSUS_DIR \
        account validator import \
        --directory $CONSENSUS_DIR/validator_keys/node$node \
        --datadir $cl_data_dir \
        --password-file $ROOT/password \
        --reuse-password 2>/dev/null
    echo -n "."
done
echo -e "\nDone importing the keystores"
