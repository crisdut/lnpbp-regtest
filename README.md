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
alias b01="docker-compose exec -T node1 bitcoin-cli -chain=regtest -rpcconnect=localhost -rpcport=18444 -rpcuser=bitcoin -rpcpassword=bitcoin"
alias b02="docker-compose exec -T node2 bitcoin-cli -chain=regtest -rpcconnect=localhost -rpcport=18444 -rpcuser=bitcoin -rpcpassword=bitcoin"

alias lnpd1="docker-compose run --rm lnp1 --network=regtest -vvvv --data-dir=/var/lib/lnp --electrum-server=electrs --electrum-port=50001"
alias lnpd2="docker-compose run --rm lnp2 --network=regtest -vvvv --data-dir=/var/lib/lnp --electrum-server=electrs --electrum-port=50001"

alias lnp01="docker-compose exec lnp1 lnp-cli -vvvv"
alias lnp02="docker-compose exec lnp2 lnp-cli -vvvv"

alias cln01="docker-compose exec cln1 lightning-cli --network=regtest"

alias rgbd1="docker-compose run --rm rgb1 -vvvv --network=regtest --bin-dir=/usr/local/bin/ --data-dir=/var/lib/rgb --electrum-server=electrs --electrum-port=50001"
alias rgbd2="docker-compose run --rm rgb2 -vvvv --network=regtest --bin-dir=/usr/local/bin/ --data-dir=/var/lib/rgb --electrum-server=electrs --electrum-port=50001"

alias rgb01="docker-compose exec rgb1 rgb-cli -vvvv --network=regtest --data-dir=/var/lib/rgb"
alias rgb02="docker-compose exec rgb2 rgb-cli -vvvv --network=regtest --data-dir=/var/lib/rgb"

alias fungible1="docker-compose exec rgb1 rgb20 -vvvv --network=regtest"
alias fungible2="docker-compose exec rgb2 rgb20 -vvvv --network=regtest"


# Update rust
rustup component add rust-src --toolchain nightly
```
### Start Nodes

### _Running L1_ 

```bash
# 1- Up and running nodes
docker-compose up -d node1 node2

# 2- Connect nodes
b01 addnode node2:18444 onetry
b02 addnode node1:18444 onetry

# 2- Generate and/or Load wallets
b01 -named createwallet wallet_name='alpha' descriptors=true # or  b01 loadwallet alpha
b02 -named createwallet wallet_name='beta' descriptors=true # or  b02 loadwallet beta

# 3- Generate two bitcoin address
addr1=$(b01 -rpcwallet=alpha getnewaddress)
addr2=$(b02 -rpcwallet=beta getnewaddress)

# 4- Generate new blocks and transfer
b01 -rpcwallet=alpha settxfee 0.00001
b02 -rpcwallet=beta settxfee 0.00001 

b01 generatetoaddress 500 $(echo $addr1)
b02 generatetoaddress 500 $(echo $addr2)

# 5- List transaction and output unspent
b01 -rpcwallet=alpha listtransactions
b01 -rpcwallet=alpha listunspent

b02 -rpcwallet=beta listtransactions
b02 -rpcwallet=beta listunspent
```

### _Running L2_

```bash
# 1- Generate funding wallet
lnpd1 init # tprv8ZgxMBicQKsPdYauyAQ2rzEptsCep1ZvuT1A2WTouSYoHGwAYicgR59irVbCuATyv4GffwJnHLvrtiHc7F4z1ckL6hP8KpeagH89CCoysSy
lnpd2 init # tprv8ZgxMBicQKsPdXjTY8BuF4WPhEhfGELSMiZM1XfLNcR2hka3wTKPqakbpMDHedYaRBJwPBeADqRnGPNHGCuqk9FUVmj5fJrzvbnoQPoTTTN

# 2- Up and running nodes
docker-compose up -d lnp1 lnp2

# 3- Connect nodes
lnp02 info 
lnp01 connect `$pb@lnp02` 

```
### _Running L3_ 

```bash
# 1- Up and running nodes
docker-compose up -d store1 store2
docker-compose up -d rgb1 rgb2 
```

### _Create Issue_

```bash
# 1- Generate new issue
ticker="USDT"
name="Tether"
```