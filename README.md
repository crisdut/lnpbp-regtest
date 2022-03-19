# Docker setup for Satoshi Racer RGB Integration (Bitcoin, LNP, BP & RGB) in regtest mode

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
docker build . -t stk-sr/lnp:0.5.0-slim
docker build . -t stk-sr/rgb:0.4.0-slim
docker build . -t stk-sr/electrs:0.9.0-alpine
docker build . -t stk-sr/bitcoin:22.0-alpine

# Command Alias (Docker)
alias b01="docker-compose exec node1 bitcoin-cli -chain=regtest -rpcconnect=localhost -rpcport=18889 -rpcuser=bitcoin -rpcpassword=bitcoin"
alias b02="docker-compose exec node2 bitcoin-cli -chain=regtest -rpcconnect=localhost -rpcport=18889 -rpcuser=bitcoin -rpcpassword=bitcoin"
alias ln01="docker-compose exec lnp1 lnp-cli"
alias rgb01="docker-compose exec rgb1 rgb-cli --network=regtest --data-dir=/var/lib/rgb/"
alias rgb02="docker-compose exec rgb2 rgb-cli --network=regtest --data-dir=/var/lib/rgb/"

alias lnpd1="docker-compose run --rm lnp1 --network=regtest --electrum-port=50001 --electrum-server=electrs"
alias lnpd2="docker-compose run --rm lnp2 --network=regtest --electrum-port=50001 --electrum-server=electrs"

alias rgbd1="docker-compose run --rm rgb1 --network=regtest --bin-dir=/usr/local/bin/ --data-dir=/var/lib/rgb/ --electrum=electrs:50001"
alias rgbd2="docker-compose run --rm rgb2 --network=regtest --bin-dir=/usr/local/bin/ --data-dir=/var/lib/rgb/ --electrum=electrs:50001"

# Update rust
rustup component add rust-src --toolchain nightly

# Generate private key (libbitcoin)
bx seed -b 128 | bx mnemonic-new | bx mnemonic-to-seed -p "" | bx hd-new
```

### Generate Token

```bash
# 0- Generate and/or Load wallets
b01 -named createwallet wallet_name='alpha' descriptor=true # or  b01 loadwallet alpha
b01 -named createwallet wallet_name='beta' descriptor=true # or  b02 loadwallet beta

# 1- Generate two bitcoin address
addr1="b01 -rpcwallet=alpha getnewaddress"
addr2="b01 -rpcwallet=beta getnewaddress"

# 2- Generate new blocks
b01 generatetoaddress 150 $addr1
b01 generatetoaddress 150 $addr2

# 3- Add TxOut Information
b01 -rpcwallet=beta listtransactions
$txid='' #1dc2dfa2988dd35116e2ac3ce17d8d87afd282ce675a9f2a3916fc5c6cbcb08c
$out=''  #0

# 4- Generate new issue
ticker="'STK01'"
name="'New Issue Description'"
rgb01 fungible issue $ticker $name --precision 0 1@$txid:$out
#-- return $contract_id=rgb1qzkpy3wrt2xyms7lhc67lrr6v93x3a7tkjxr698286qarx2n3wcslhlevj

# 5- Generate blind utxo
rgb01 fungible blind $txid:$out
#-- return $blind="utxob17cemvl28ctgnrx45shx2z7nxz3hlkspvupd6ay78laqdn9ysc2zsjkm6t8"
#-- return $blind_secret="8418017085025344047"

# 6- Generate psbt source

# 7- Generate psbt destination

# 8- Create new transfer
rgb01 fungible transfer $dest_txid 1 $contract_id $psbt ./tmp/consignment.rgb ./tmp/disclosure.rgb ./tmp/invoice.rgb

# 9- Accept transfer

# 10- Check transfer

```
