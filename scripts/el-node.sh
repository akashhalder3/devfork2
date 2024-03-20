#!/usr/bin/env bash

source ./scripts/util.sh
set -u +e

cleanup() {
    kill $(jobs -p) 2>/dev/null
}

trap cleanup EXIT

index=$1
boot_enode="enode://82cff4d29c4a4239d84388c586ee0f1c73abe50c3867b36ae494a5507319e2a2ae0fb3d97e41dd7e3090352090ef4b0da6f6087883bfd16cf2a3a1010ca89300@20.40.53.142:21001"

el_data_dir $index
datadir=$el_data_dir
address=$(cat $datadir/address)
port=$(expr $BASE_EL_PORT + $index)
rpc_port=$(expr $BASE_EL_RPC_PORT + $index)
http_port=$(expr $BASE_EL_HTTP_PORT + $index)
ws_port=$(expr $BASE_EL_WS_PORT + $index)
log_file=$datadir/geth.log

echo "Started the geth node #$index which is now listening at port $port and rpc at port $rpc_port with HTTP server at port $http_port. You can see the log at $log_file"
$GETH_CMD \
    --datadir $datadir \
    --authrpc.addr="0.0.0.0" \
    --authrpc.port $rpc_port \
    --authrpc.vhosts "*" \
    --port $port \
    --bootnodes $boot_enode \
    --networkid $NETWORK_ID \
    --http \
    --http.api admin,net,eth,web3,debug \
    --http.addr="0.0.0.0" \
    --http.port $http_port \
    --http.corsdomain "*" \
    --ws \
    --ws.port $ws_port \
    --ws.api admin,net,eth,web3,debug \
    --ws.addr="0.0.0.0" \
    --ws.origins "*" \
    --syncmode "full" \
    --allow-insecure-unlock \
    --unlock $address \
    --password $ROOT/password \
    --rpc.allow-unprotected-txs \
    --nat extip:20.244.97.158 \
    < /dev/null > $log_file 2>&1

if test $? -ne 0; then
    node_error "The geth node #$index returns an error. The last 10 lines of the log file is shown below.\n\n$(tail -n 10 $log_file)"
    exit 1
fi