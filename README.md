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

# 6- Send coins to Issue Address (After create Taproot wallet)
$issueaddr="tb1..."
b01 sendtoaddress $issueaddr 0.001
b01 generatetoaddress 10 $(echo $addr1)

# 7- Send coins to change Address (After create Taproot wallet)
$changeaddr="tb1..."
b01 sendtoaddress $changeaddr 0.00001
b01 generatetoaddress 10 $(echo $addr1)
```

### _Running L2_

```bash
# 1- Generate funding wallet
lnpd1 init # tprv8fRNBaNZGS76x6KDSVKL3FyT6kL5TPEG9m27xNq1e2Fgo3AaWwJsu7vac8uH5BMUtbeFbob7TuMaQYSFQT8AFAjoAPDyvKLmcWoX3KLDR6y
lnpd2 init # tprv8ZgxMBicQKsPdXjTY8BuF4WPhEhfGELSMiZM1XfLNcR2hka3wTKPqakbpMDHedYaRBJwPBeADqRnGPNHGCuqk9FUVmj5fJrzvbnoQPoTTTN

# 2- Up and running nodes
docker-compose up -d lnp1 lnp2

# 3- Connect nodes
lnp1_ip='172.20.0.8'   # example
lnp1_port='9735'        # example
lnp2_ip='172.20.0.10'   # example
lnp2_port='9735'        # example

lnp01 listen # or set --listen parameters on initalization of the node
lnp02 listen # or set --listen parameters on initalization of the node

lnp02 info # get public key
lnp01 connect "$pb@$lnp2_ip:$lnp2_port"

```
### _Running L3_ 

```bash
# 1- Up and running nodes
docker-compose up -d store1 store2
docker-compose up -d rgb1 rgb2 
docker-compose up -d storm1 storm2
```

### _Create Issue_

```bash
# 1- Generate
txid='...' #example (issuer transaction)
vout='...' #example (issuer vout)

ticker="SRC"
name="Satoshi Racer Coin"
amount="100"
allocation="$amount@$txid:$vout"

fungible1 issue "$ticker" "$name" "$allocation"
# Output=> $contractID="rgb1..."
# Output=> $contract="rgbc1..."

# 2- Sync Contract
rgb01 contract register $contract

# 3- Create Blind UTXO
unspent_txid='...' #example (change transaction)
unspent_vout='...' #example (change vout)

rgbstd1 blind $unspent_txid:$unspent_vout
seal_definition="txob..."
blind_factor="..."
```

### _Create and Send Consignment_
```bash
# 1- Prepare Consignment (State Transfer)
rgb01 transfer compose $contractID $txid:$vout /var/lib/rgb/consignment.rgb
rgbstd1 consignment validate /var/lib/rgb/consignment.rgb

# 2- Prepare to Transfer
atomic_value=90
transfer_value="$atomic_value@tapret1st:$unspent_txid:$unspent_vout"

fungible1 transfer --utxo "$txid:$vout" --change $transfer_value /var/lib/rgb/consignment.rgb \
          "10@$seal_definition" /var/lib/rgb/transfer.rgb

# 3- Transfer Asset (After Create PSBT**)
# docker cp ./shared/psbt.rgb [DOCKER_CONTAINER_ID]:/var/lib/rgb/  <--- for docker noobs =)
rgb01 contract embed $contractID /var/lib/rgb/psbt.rgb 
rgb01 transfer combine $contractID /var/lib/rgb/transfer.rgb /var/lib/rgb/psbt.rgb  "$txid:$vout" 

# 4- Check PSBT Transfer
rgbstd1 psbt bundle /var/lib/rgb/psbt.rgb
rgbstd1 psbt analyze /var/lib/rgb/psbt.rgb

# 5- Make a Transfer
rgb01 transfer finalize --endseal $seal_definition /var/lib/rgb/psbt.rgb /var/lib/rgb/consignment.rgb --send "$pb@$lnp1_ip:$lnp1_port"
rgbstd1 consignment validate /var/lib/rgb/consignment.rgb

# 6- Check Transfer (After Sign PSBT**)
rgbstd1 consignment validate /var/lib/rgb/consignment.rgb
```

### _Bonus: Create PSBT_

```bash
# 1- Generate seed and private key
btc-hot seed -P ./tr.seed

# 2- Save Wallet Descriptor
btc-hot derive --testnet --scheme bip86 -P ./tr.seed ./tr.derive
wl="tr(m=[..."

echo $wl > ./tr.wd

# 4- Generate Wallet
btc-cold create ./tr.wd ./tr.wallet -e $electrum_host -p $electrum_port

# 5- Get Address
btc-cold address ./tr.wallet  -e $electrum_host -p $electrum_port
addr_dw="tb1p..."

# 5- Construct PSBT (Retrieve UTXO)
fee=100
btc-cold check tr.wallet -e $electrum_host -p $electrum_port
btc-cold construct --input "$txid:$vout /0/0" --allow-tapret-path 1 ./tr.wallet ./psbt.rgb -e $electrum_host -p $electrum_port $fee
```

### _Bonus2: Sign PSBT_

```bash
# 1- Create Anchor
# docker cp [DOCKER_CONTAINER_ID]:/var/lib/rgb/psbt.rgb ./shared/psbt.rgbt    <--- for docker noobs =)
dbc commit ./shared/psbt.rgbt ./shared/psbt.final

# 2- Sign PSBT
btc-hot sign ./shared/psbt.final ./tr.derive

# 4- Finalize
btc-cold finalize --publish regtest ./shared/psbt.final -e $electrum_host -p $electrum_port

```