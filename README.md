# Unofficial LNPBP Stack and ecosystem in regtest mode

### ONLY FOR DEVELOPMENT and TESTING. These tools may not be suitable for production deployments.

### Notes & prerequisites

- `docker` and `docker-compose` installation is required (https://docs.docker.com/install/).
- `jq` tool is used in examples for parsing json responses.
- All nodes will sync to chain after the first Bitcoin regtest blocks are generated.
- Ports and other daemon configuration can be changed in the `.env` and `docker-compose.yml` files.

### Supported Nodes and Libs
* Bitcoin Core v24
* Core Lightning v22.11
* Electrs v0.9.10
* Esplora v2.10 (Bitcoin Core v22)
* BP Node v0.8.0
* RGB Node v0.8.2
* LNP Node v0.8.0
* Store Node v0.8.0
* Storm Node v0.8.0
* RGB Std v0.8.1
* RGB 20 v0.8.0
* RGB 121 v0.1.0


### Instructions

- Generate a individual docker image to each node.

### Commands

```bash
# Build Docker Images
docker-compose build

# Load Commands
source .commands
```

### Install Dependencies

### _Install Wallet Descriptor and DBC_
```bash
cargo install descriptor-wallet --version "0.8.3" --all-features --locked
```

### Start Nodes


### _Running L1_

```bash
# 1- Up and running nodes
docker-compose up -d electrs node1 node2
# b01 addnode node2:18444 onetry
# b02 addnode node1:18444 onetry

# 2- Generate and/or Load wallets
# TODO: https://gist.github.com/pinheadmz/cbf419396ac983ffead9670dde258a43
b01 -named createwallet wallet_name='alpha' descriptors=true # or  b01 loadwallet alpha
b02 -named createwallet wallet_name='beta' descriptors=true # or  b02 loadwallet beta

# 3- Generate two bitcoin address
addr1=$(b01 -rpcwallet=alpha getnewaddress)
addr2=$(b02 -rpcwallet=beta getnewaddress)

# 4- Mine new blocks
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

### _Running APPs_


### _Running L2_

```bash
# 1- Generate funding wallet
lnpd1 init # tprv8gD6szk1Vr8Bm3dY4wpxodYwkZihHM8XLWypXiUTcuQamaMwUHKDoJZJfjY3kCCzRe9PUmeWz3UtQtPJnbJsykoarXpQrgNqu2vXUcydtR2
lnpd2 init # tprv8ZgxMBicQKsPdXjTY8BuF4WPhEhfGELSMiZM1XfLNcR2hka3wTKPqakbpMDHedYaRBJwPBeADqRnGPNHGCuqk9FUVmj5fJrzvbnoQPoTTTN

lnd01 create

# 2- Up and running nodes
docker-compose up -d lnp1 lnp2 cln1 cln2 lnd01

# 3- Connect nodes (Bifrost)
lnp1_ip='172.20.0.8'
lnp1_port='9997'
lnp2_ip='172.20.0.10'
lnp2_port='9998'

lnp01 listen --bifrost -p $lnp1_port
lnp02 listen --bifrost -p $lnp2_port

lnp02 info --bifrost # get pb2
lnp01 connect "bifrost://$pb2@$lnp2_ip:$lnp2_port"

# 4- Connect nodes (Bolt)
lnp1_ip='172.20.0.8'
lnp1_port='9735'
cln1_ip='172.20.0.12'
cln1_port='19755'
cln2_ip='172.20.0.30'
cln2_port='19755'

lnp01 listen --bolt -p $lnp1_port
lnp02 listen --bolt -p $lnp2_port

cln01 getinfo # get pb3
lnp01 connect "bolt://$pb3@$cln1_ip:$cln1_port"

# 5 - Check peers
lnp01 peers
lnp02 peers
cln01 listpeers

# 6 - Add funding address
lnp01 funds
cln01 listfunds
b01 generatetoaddress 10 $(echo $addr1)

# 7 - Create a channel (Bolt)
lnp01 open "$pb3@$cln1_ip:$cln1_port" 10000
cln01 fundchannel $pb1 10000

```
### _Running L3_

```bash
# 1- Up and running nodes
docker-compose up -d store1 store2
docker-compose up -d storm1 storm2
docker-compose up -d rgb1 rgb2
```

### _Explore Use Cases_

```
./usecases
│   1_issuer_asset.md
│   2_atomic_swap.md
```