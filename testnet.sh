#!/usr/bin/env bash
NODE_COUNT=${NODE_COUNT:-1}
VALIDATOR_COUNT=${VALIDATOR_COUNT:-2}
ROOT=${ROOT:-./data}
BUILD_DIR=${BUILD_DIR:-./build}
GETH_CMD=${GETH_CMD:-geth}
LIGHTHOUSE_CMD=${LIGHTHOUSE_CMD:-lighthouse}

NETWORK_ID=6969

CONSENSUS_DIR=$ROOT/consensus
EXECUTION_DIR=$ROOT/execution

GENESIS_FILE=$EXECUTION_DIR/genesis.json
CONFIG_FILE=$CONSENSUS_DIR/config.yaml

SIGNER_PORT=3011
SIGNER_RPC_PORT=3012
SIGNER_HTTP_PORT=3013
SIGNER_EL_DATADIR=$ROOT/signer/ethereum

BASE_EL_PORT=21000
BASE_EL_RPC_PORT=8600
BASE_EL_WS_PORT=8546
BASE_HTTP_PORT=7999

BASE_CL_PORT=31000
BASE_CL_HTTP_PORT=9600

source ./scripts/util.sh
set -u +e

if ! test $(uname -s) = "Linux"; then
    echo "Only Linux is supported"
fi

check_cmd() {
    if ! command -v $1 >/dev/null; then
        echo -e "\nCommand '$1' not found, please install it first.\n\n$2\n"
        exit 1
    fi
}

if test -e $ROOT; then
    echo "The file $ROOT already exists, please delete or move it first."
    exit 1
fi

check_cmd geth "See https://geth.ethereum.org/docs/getting-started/installing-geth for more detail."
check_cmd bootnode "See https://geth.ethereum.org/docs/getting-started/installing-geth for more detail."
check_cmd lighthouse "See https://lighthouse-book.sigmaprime.io/installation.html for more detail."
check_cmd lcli "See https://lighthouse-book.sigmaprime.io/installation-source.html and run \"make install-lcli\"."
check_cmd npm "See https://nodejs.org/en/download/ for more detail."
check_cmd node "See https://nodejs.org/en/download/ for more detail."


mkdir -p $ROOT

# Run everything needed to generate $BUILD_DIR
if ! ./scripts/build.sh; then
    echo -e "\n*Failed!* in the build step\n"
    exit 1
fi

./deposit \
--language english \
--non_interactive \
existing-mnemonic \
--num_validators 1 \
--mnemonic="abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about" \
--validator_start_index 3 \
--chain kiln

geth \
--datadir /home/azureuser/devfork2/data/node1/ethereum \
--authrpc.addr="0.0.0.0" \
--authrpc.port 3012 \
--port 3011 \
--http \
--http.api admin,eth,miner,net,txpool,personal,web3 \
--http.addr=0.0.0.0 \
--http.port 3013 \
--http.corsdomain="*" \
--ws \
--ws.api eth,net,web3 \
--ws.origins "*" \
--networkid 38356 \
--allow-insecure-unlock \
--unlock 0xf86c59670afbadef08ee00bdbaac52d4d892fcc2 \
--syncmode "full" \
--password /home/azureuser/devfork2/password \
--nat=extip:20.244.97.158


lighthouse \
--testnet-dir /home/azureuser/devfork2/data/consensus \
account validator import \
--directory /home/azureuser/devfork2/build/validator_keys \
--datadir /home/azureuser/devfork2/data/consensus/validator_keys/node1 \
--reuse-password

lighthouse beacon_node \
--datadir /home/azureuser/devfork2/data/node1/lighthouse \
--testnet-dir /home/azureuser/devfork2/data/consensus \
--execution-endpoint http://localhost:3013 \
--execution-jwt /home/azureuser/devfork2/data/node1/lighthouse/jwtsecret \
--enable-private-discovery \
--staking \
--enr-address 20.244.97.158 \
--enr-udp-port 31000 \
--enr-tcp-port 31000 \
--port 31000 \
--http \
--http-address 0.0.0.0 \
--http-port 9601 \
--boot-nodes enr:-MS4QEEdSayp1AN4AN-Jckg4rd2XDOZ8wOA7jeuN8EO6vwOzZuZ2QEBJ6RnuWi0mbykwH4VPEeSB7g02Yep_dl8LIdQLh2F0dG5ldHOIBgAAAAAAAACEZXRoMpCCGKyJAgAAAf__________gmlkgnY0gmlwhBQoNY6EcXVpY4J5GolzZWNwMjU2azGhAuR8Ti-Kf0faGlNs4UcPVELtNFZ8_TFJx_6q89xnGhW_iHN5bmNuZXRzD4N0Y3CCeRmDdWRwgnkZ \
--http-allow-sync-stalled


lighthouse validator_client \
--datadir /home/azureuser/devfork2/node1/lighthouse \
--testnet-dir /home/azureuser/devfork2/consensis \
--init-slashing-protection \
--beacon-nodes http://localhost:9601 \
--suggested-fee-recipient 0x89f47a3531d2b659ec6fca1d730c1bcb747e7f4f