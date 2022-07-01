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
docker-compose build

# Command Alias (Docker)
alias b01="docker-compose exec node1 bitcoin-cli -chain=regtest -rpcconnect=localhost -rpcport=18889 -rpcuser=bitcoin -rpcpassword=bitcoin"
alias b02="docker-compose exec node2 bitcoin-cli -chain=regtest -rpcconnect=localhost -rpcport=18889 -rpcuser=bitcoin -rpcpassword=bitcoin"

alias rgbd1="docker-compose run --rm rgb1 -vvvv --network=regtest --bin-dir=/usr/local/bin/ --data-dir=/var/lib/rgb/ --electrum=electrs:50001"
alias rgbd2="docker-compose run --rm rgb2 -vvvv --network=regtest --bin-dir=/usr/local/bin/ --data-dir=/var/lib/rgb/ --electrum=electrs:50001"

alias lnpd1="docker-compose run --rm lnp1 --network=regtest -vvvv --data-dir=/var/lib/lnp/"
alias lnpd2="docker-compose run --rm lnp2 --network=regtest -vvvv --data-dir=/var/lib/lnp/"

alias rgb01="docker-compose exec rgb1 rgb-cli -vvvv --network=regtest --data-dir=/var/lib/rgb/"
alias rgb02="docker-compose exec rgb2 rgb-cli -vvvv --network=regtest --data-dir=/var/lib/rgb/"

alias fungible1="docker-compose exec rgb1 rgb20 -vvvv --network=regtest"
alias fungible2="docker-compose exec rgb2 rgb20 -vvvv --network=regtest"

alias lnp01="docker-compose exec lnp1 lnp-cli -vvvv"
alias lnp02="docker-compose exec lnp2 lnp-cli -vvvv"

alias cln01="docker-compose exec cln1 lightning-cli --network=regtest"

# Update rust
rustup component add rust-src --toolchain nightly
```

### Start Network and Funding Wallet 

```bash
# 1- Generate and/or Load wallets
b01 -named createwallet wallet_name='alpha' descriptors=true # or  b01 loadwallet alpha
b02 -named createwallet wallet_name='beta' descriptors=true # or  b02 loadwallet beta

# 2- Generate two bitcoin address
addr1="b01 -rpcwallet=alpha getnewaddress"
addr2="b02 -rpcwallet=beta getnewaddress"

# 3- Generate new blocks and transfer
b01 -rpcwallet=alpha settxfee 0.00001
b01 generatetoaddress 500 $addr1
b01 -rpcwallet=beta listunspent

b02 -rpcwallet=beta settxfee 0.00001 
b02 generatetoaddress 500 $addr2

# 4- List transaction and output unspent
b01 -rpcwallet=alpha listtransactions
# Example
# $txid='1dc2dfa2988dd35116e2ac3ce17d8d87afd282ce675a9f2a3916fc5c6cbcb08c'
# $out='0'

# 5- Generate funding wallet
lnpd1 init
# Example
# $pk='tprv8ZgxMBicQKsPdYauyAQ2rzEptsCep1ZvuT1A2WTouSYoHGwAYicgR59irVbCuATyv4GffwJnHLvrtiHc7F4z1ckL6hP8KpeagH89CCoysSy'
```

### Create new Asset 

```bash
# 1- Generate new issue
ticker="USDT"
name="Tether"
```