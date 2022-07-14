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
source .env

alias b01="docker-compose exec -T node1 bitcoin-cli -chain=regtest -rpcconnect=localhost -rpcport=${BITCOIN_RPC_PORT} -rpcuser=${BITCOIN_RPC_USER} -rpcpassword=${BITCOIN_RPC_PASSWORD}"
alias b02="docker-compose exec -T node2 bitcoin-cli -chain=regtest -rpcconnect=localhost -rpcport=${BITCOIN_RPC_PORT} -rpcuser=${BITCOIN_RPC_USER} -rpcpassword=${BITCOIN_RPC_PASSWORD}"

alias lnpd1="docker-compose run --rm lnp1 --network=regtest -vvvv --data-dir=${LNP_DATA_DIR} --electrum-server=${ELECTRS_IP} --electrum-port=${ELECTRS_PORT}"
alias lnpd2="docker-compose run --rm lnp2 --network=regtest -vvvv --data-dir=${LNP_DATA_DIR} --electrum-server=${ELECTRS_IP} --electrum-port=${ELECTRS_PORT}"

alias lnp01="docker-compose exec -T lnp1 lnp-cli -vvvv"
alias lnp02="docker-compose exec -T lnp2 lnp-cli -vvvv"

alias cln01="docker-compose exec cln1 lightning-cli --network=regtest"

alias rgbd1="docker-compose run --rm rgb1 -vvvv --network=regtest --bin-dir=${RGB_BIN_DIR} --data-dir=${RPC_DATA_DIR} --electrum-server=${ELECTRS_HOST} --electrum-port=${ELECTRS_PORT}"
alias rgbd2="docker-compose run --rm rgb2 -vvvv --network=regtest --bin-dir=${RGB_BIN_DIR} --data-dir=${RGB_DATA_DIR} --electrum-server=${ELECTRS_HOST} --electrum-port=${ELECTRS_PORT}"

alias rgb01="docker-compose exec -T rgb1 rgb-cli -vvvv --network=regtest"
alias rgb02="docker-compose exec -T rgb2 rgb-cli -vvvv --network=regtest"

alias fungible1="docker-compose exec -T rgb1 rgb20 --network=regtest"
alias fungible2="docker-compose exec -T rgb2 rgb20 --network=regtest"

alias rgbstd1="docker-compose exec -T rgb1 rgb"
alias rgbstd2="docker-compose exec -T rgb2 rgb"

alias storm01="docker-compose exec storm1 storm-cli -vvvv --lnp=${LNP_IP_1}:${LNP_RPC_PORT}"
alias storm02="docker-compose exec storm2 storm-cli -vvvv --lnp=${LNP_IP_2}:${LNP_RPC_PORT}"

alias chat1="docker-compose run --rm chat1 --data-dir=${STORM_DATA_DIR}"
alias file1="docker-compose run --rm file1 --data-dir=${STORM_DATA_DIR}"

# Update rust
rustup component add rust-src --toolchain nightly
```
### Start Nodes

### _Running L1_ 

```bash
# 1- Up and running nodes
docker-compose up -d node1 node2 electrs

# 2- Connect nodes
b01 addnode node2:18444 onetry
b02 addnode node1:18444 onetry

# 2- Generate and/or Load wallets
# CHANGE HERE > https://gist.github.com/pinheadmz/cbf419396ac983ffead9670dde258a43
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

# 6- Send coins (After create Taproot wallet)
$tapaddr="tb1..."
b01 sendtoaddress $tapaddr 0.00001
b01 generatetoaddress 10 $(echo $addr1)
```

### _Running L2_

```bash
# 1- Generate funding wallet
lnpd1 init # tprv8ZgxMBicQKsPdYauyAQ2rzEptsCep1ZvuT1A2WTouSYoHGwAYicgR59irVbCuATyv4GffwJnHLvrtiHc7F4z1ckL6hP8KpeagH89CCoysSy
lnpd2 init # tprv8ZgxMBicQKsPdXjTY8BuF4WPhEhfGELSMiZM1XfLNcR2hka3wTKPqakbpMDHedYaRBJwPBeADqRnGPNHGCuqk9FUVmj5fJrzvbnoQPoTTTN

# 2- Up and running nodes
docker-compose up -d lnp1 lnp2

# 3- Connect nodes
lnp2_ip='172.20.0.11'   # example
lnp2_port='9735'        # example

lnp01 listen # or set --listen parameters on initalization of the node
lnp02 listen # or set --listen parameters on initalization of the node

lnp02 info # get public key
lnp01 connect `$pb@$lnp2_ip:$lnp2_port` 

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
txid='8aa3e74100bbbd437c47c5c6e752cec0a5865e640457a3361c65eb31cfc7c7b2' #example (psbt unspent)
vout='0' #example

ticker="SRC"
name="Satoshi Racer Coin"
amount="100"
allocation="$amount@$txid:$vout"

fungible1 issue "$ticker" "$name" $allocation
# Output=> $contractID="rgb1..."
# Output=> $contract="rgbc1..."

# 2- Sync Contract
rgb01 contract register $contract

# 2- Prepare Consignment (State Transfer)
unspent_txid='a32328468978cf09092e2b55525e3a9228a639032d9f569a650ddb57231ebfff' #example
unspent_vout='0' #example

rgb01 compose $contractID $unspent_txid:$unspent_vout /var/lib/rgb/consignment.rgb
# docker cp [DOCKER_CONTAINER_ID]:/var/lib/rgb/consignment.rgb ./shared/ <--- for docker noobs =)

# 3- Create Blind UTXO
dest_txid='27349fc4a6bde9e8f6c7c69761d5a0f0ffa3f1cd9936a802b7bd4261bcb2b8ff' #example
dest_vout='0' #example

rgbstd1 blind $dest_txid:$dest_vout
# Output=> txob15ujk37vftssl4eh0a2x72cce2d7q5rgwxjy68k2z4pxtm86r2v3snak74y (Seal Definition)
# Output=> 16669351361466217679 (Blinding factor)

# 4- Prepare to Transfer
atomic_value=$amount
transfer_value="$atomic_value@$seal_definition"
fungible1 transfer --utxo "$txid:$vout" /var/lib/rgb/consignment.rgb $transfer_value /var/lib/rgb/transfer.rgb

# 5- Transfer Asset (After Create PSBT)
rgb01 transfer $contractID /var/lib/rgb/transfer.rgb /var/lib/rgb/psbt.rgb 

# 6- Confirm Transfer
```

### _Bonus: Create PSBT_

```bash
# 1- Generate seed and private key
btc-hot seed -P ./tr.seed

# 2- Save Wallet Descriptor
btc-hot derive --testnet -P ./tr.seed ./tr.derive
wl="tr(m=[..."

cat $wl > ./tr.wd

# 4- Generate Wallet
btc-cold create ./tr.wd ./tr.wallet

# 5- Get Address
btc-cold address ./tr.wallet
addr_dw="tb1p..."

# 6- Transfer and Mine
b01 -rpcwallet=alpha sendtoaddress $addr_dw 100
b01 -rpcwallet=alpha generatetoaddress 500 $(echo $addr1)

# 6- Construct PSBT (Retrieve UTXO)
btc-cold check tr.wallet -e $electrum_host -p $electrum_port
btc-cold construct ./tr.wallet ./psbt.rgb 1000 --input "$txid:$vout /0/0 rbf" -e $electrum_host -p $electrum_port
```