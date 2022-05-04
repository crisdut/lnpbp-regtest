# Docker setup for Satoshi Racer Nodes (LNP, RGB & DLC integration) in regtest mode

### ONLY FOR DEVELOPMENT and TESTING. These tools may not be suitable for production deployments.

### Notes & prerequisites

- `docker` and `docker-compose` installation is required (https://docs.docker.com/install/).
- `jq` tool is used in examples for parsing json responses.
- All nodes will sync to chain after the first Bitcoin regtest blocks are generated.
- Ports and other daemon configuration can be changed in the `.env` and `docker-compose.yml` files.

### Instructions

- Generate a individual docker image to each node.

### Commands

```bash
# Build Docker Images
docker build . -t sr-rgb:0.1.0
docker build . -t sr-btc:0.1.0
docker build . -t sr-electrs:0.1.0

# Command Alias (Docker)
alias b01="docker-compose exec node1 bitcoin-cli -chain=regtest -rpcconnect=localhost -rpcport=18889 -rpcuser=bitcoin -rpcpassword=bitcoin"
alias rgb01="docker-compose exec rgb1 rgb-cli --network=regtest --data-dir=/var/lib/rgb/"
alias rgb02="docker-compose exec rgb2 rgb-cli --network=regtest --data-dir=/var/lib/rgb/"

alias rgbd1="docker-compose run --rm rgb1 --network=regtest --bin-dir=/usr/local/bin/ --data-dir=/var/lib/rgb/ --electrum=electrs:50001"
alias rgbd2="docker-compose run --rm rgb2 --network=regtest --bin-dir=/usr/local/bin/ --data-dir=/var/lib/rgb/ --electrum=electrs:50001"

# Update rust
rustup component add rust-src --toolchain nightly
```

### Generate Token

```bash
# 0- Generate and/or Load wallets
b01 -named createwallet wallet_name='alpha' descriptors=true # or  b01 loadwallet alpha
b01 -named createwallet wallet_name='beta' descriptors=true # or  b02 loadwallet beta

# 1- Generate two bitcoin address
addr1="b01 -rpcwallet=alpha getnewaddress"
addr2="b01 -rpcwallet=beta getnewaddress"
addr3="b01 -rpcwallet=beta getnewaddress"

# 2- Generate new blocks and transfer
b01 generatetoaddress 500 $addr1
b01 -rpcwallet=alpha settxfee 0.00001
b01 -rpcwallet=alpha sendtoaddress $addr2 2 
b01 -rpcwallet=alpha sendtoaddress $addr3 1 
b01 -rpcwallet=beta listunspent

# 3- Add TxOut Information
b01 -rpcwallet=alpha listtransactions
# Example
# $txid='1dc2dfa2988dd35116e2ac3ce17d8d87afd282ce675a9f2a3916fc5c6cbcb08c'
# $out='0'

# $change_txid='1dc2dfa2988dd35116e2ac3ce17d8d87afd282ce675a9f2a3916fc5c6cbcb08c'
# $change_out='0'

# $dest_txid='1dc2dfa2988dd35116e2ac3ce17d8d87afd282ce675a9f2a3916fc5c6cbcb08c'
# $dest_out='0'

# 4- Generate new issue
ticker="STK01"
name="Fungible (Sample)"
rgb01 fungible issue $ticker $name --precision 0 1@$txid:$out
# Example
# $contract_id=rgb1qzkpy3wrt2xyms7lhc67lrr6v93x3a7tkjxr698286qarx2n3wcslhlevj

# 5- Generate blind utxo
rgb02 fungible blind $dest_txid:$dest_out
#Example
# $blind="utxob17cemvl28ctgnrx45shx2z7nxz3hlkspvupd6ay78laqdn9ysc2zsjkm6t8"
# $blind_secret="8418017085025344047"

# 6- Generate psbt source

# 7- Create new transfer
rgb01 fungible transfer $blind 1 $asset_id $psbt /var/lib/rgb/consignment.rgb /var/lib/rgb/disclosure.rgb /var/lib/rgb/invoice.rgb -a $txid:$out -i $change_txid:$change_out

# 9- Accept transfer
rgb02 fungible accept /var/lib/rgb/consignment.rgb $dest_txid:$ $blind_secret

# 10- Check transfer (Updated)
rgb01 fungible enclose /var/lib/rgb/disclosure.rgb

```
