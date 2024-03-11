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

$GETH_CMD \
    --datadir /home/azureuser/devfork2/node1/ethereum \
    --authrpc.port $SIGNER_RPC_PORT \
    --port $SIGNER_PORT \
    --http \
    --http.addr=0.0.0.0 \
    --http.port $SIGNER_HTTP_PORT \
    --http.corsdomain="*" \
    --allow-insecure-unlock \
    --bootnodes enode://f6612e64567415bca4d5a11997aa022f13b46b2e4abbbfa8c9608ba2e00d0a07901349a58aaa7cc671d09478cb50e5515088f6318f003f3d682fa1179bd372d5@20.244.97.158:21001 \
    --networkid $NETWORK_ID \
    --unlock 0x6f3d01787f34716934f220052482eEaE8D2a1579 \
    --mine \
    --miner.etherbase 0x6f3d01787f34716934f220052482eEaE8D2a1579 \
    --syncmode "full" \
    < /dev/null > /home/azureuser/devfork2/node1/ethereum/logs/geth.log 2>&1