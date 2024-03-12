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

geth \
    --datadir /home/azureuser/devfork2/node1/ethereum \
    --authrpc.addr="0.0.0.0" \
    --authrpc.port 3012 \
    --port 3011 \
    --http \
    --http.addr=0.0.0.0 \
    --http.port 3013 \
    --http.corsdomain="*" \
    --allow-insecure-unlock \
    --bootnodes enode://f36929f5efa63c8d7b469cc626b99982d862633584f5e26f9aced27f3895e2a7a620b785cd7046592159647719f9523efb2d1445a2c4bb40d29981c1c940baeb@20.244.97.158:21001 \
    --networkid 6969 \
    --unlock 0x6f3d01787f34716934f220052482eEaE8D2a1579 \
    --mine \
    --miner.etherbase 0x6f3d01787f34716934f220052482eEaE8D2a1579 \
    --syncmode "full" \
    --nat=extip:20.40.53.142


lighthouse \
    --testnet-dir /home/azureuser/devfork2/consensis \
    account validator import \
    --directory /home/azureuser/devfork2/build/validator_keys \
    --datadir /home/azureuser/devfork2/node1/lighthouse \
    --password-file /home/azureuser/devfork2/password \
    --reuse-password

lighthouse beacon_node \
--datadir /home/azureuser/devfork2/node1/lighthouse \
--testnet-dir /home/azureuser/devfork2/consensis \
--execution-endpoint http://localhost:3013 \
--execution-jwt /home/azureuser/devfork2/node1/lighthouse/jwtsecret \
--enable-private-discovery \
--staking \
--enr-address 0.0.0.0 \
--enr-udp-port 31000 \
--enr-tcp-port 31000 \
--port 31000 \
--http \
--http-address 0.0.0.0 \
--http-port 9601 \
--disable-packet-filter \
--http-allow-sync-stalled \
--subscribe-all-subnets \
--disable-enr-auto-update \
--boot-nodes=enr:-MS4QK09T2f1KB3LvpHXNNTZSnW_r7G0Z0E_UVfQvANeMRqUfHSa50qNavePaFFLJhKNBxIZh1l-fVMP2rYKvh98aCMDh2F0dG5ldHOIAAAAAAAAAACEZXRoMpD0p_e7AQAAAQEAAAAAAAAAgmlkgnY0gmlwhH8AAAGEcXVpY4J5HolzZWNwMjU2azGhAlHaqVwWRNCPeldZp-zrLXh1jI67uDD_nogF6ZpgeeBUiHN5bmNuZXRzAIN0Y3CCeR2DdWRwgnkd

lighthouse validator_client \
--datadir /home/azureuser/devfork2/node1/lighthouse \
--testnet-dir /home/azureuser/devfork2/consensis \
--init-slashing-protection \
--beacon-nodes http://localhost:9601 \
--suggested-fee-recipient 0xfa2f8e391a2776fe088a091ab3bce80b85cd6b0d