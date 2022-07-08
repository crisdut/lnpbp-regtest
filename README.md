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

alias lnp01="docker-compose exec -T lnp1 lnp-cli -vvvv"
alias lnp02="docker-compose exec -T lnp2 lnp-cli -vvvv"

alias cln01="docker-compose exec cln1 lightning-cli --network=regtest"

alias rgbd1="docker-compose run --rm rgb1 -vvvv --network=regtest --bin-dir=/usr/local/bin/ --data-dir=/var/lib/rgb --electrum-server=electrs --electrum-port=50001"
alias rgbd2="docker-compose run --rm rgb2 -vvvv --network=regtest --bin-dir=/usr/local/bin/ --data-dir=/var/lib/rgb --electrum-server=electrs --electrum-port=50001"

alias rgb01="docker-compose exec -T rgb1 rgb-cli -vvvv --network=regtest"
alias rgb02="docker-compose exec -T rgb2 rgb-cli -vvvv --network=regtest"

alias fungible1="docker-compose exec -T rgb1 rgb20 --network=regtest"
alias fungible2="docker-compose exec -T rgb2 rgb20 --network=regtest"


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

# CHANGE HERE > https://gist.github.com/pinheadmz/cbf419396ac983ffead9670dde258a43
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
txid='2c9b0f0c4346860357c6b8fafd459a288e409a8141507b7e2a5ef1716f5c82b7' #example
vout='0' #example

ticker="SRC"
name="Satoshi Racer Coin"
amount="100"
allocation="$amount@$txid:$vout"

fungible1 issue "$ticker" "$name" $allocation
# Output=> $contractID="rgb1..."
# Output=> $contract="rgbc1..."

# 2- Sync Contract
rgb01 register $contract

# 2- Prepare Consignment (State Transfer)
unspent_txid='e2250abfdcbcf9240e065ecf304cd86cfb0a7f45e5a5f0627c82d8c9365ca4ff' #example
unspent_vout='0' #example

rgb01 compose $contractID $unspent_txid:$unspent_vout /var/lib/rgb/consignment.rgb
# docker cp [DOCKER_CONTAINER_ID]:/var/lib/rgb/consignment.rgb ./shared/ <--- for docker noobs =)

# 3- Create Blind UTXO
dest_txid='fb10344c488c66408310f8e47ebc9f3776d23b0595c07ee16814c725ee6eb2ff' #example
dest_vout='0' #example

fungible1 blind $dest_txid:$dest_vout
# Output=> txob15ujk37vftssl4eh0a2x72cce2d7q5rgwxjy68k2z4pxtm86r2v3snak74y (Seal Definition)
# Output=> 16669351361466217679 (Blinding factor)

# 4- Prepare to Transfer
transfer_value="$atomic_value@$seal_definition"
fungible1 transfer --utxo $txid:$vout /var/lib/rgb/consignment.rgb $transfer_amount /var/lib/rgb/transfer.rgb

# 5- Transfer Asset (After Create PSBT)
rgb01 transfer $contractID /var/lib/rgb/transfer.rgb 

# 6- Pay Invoice
# 6- Confirm Payment
```

### _Bonus: Create PSBT_

```bash
# 1- Export wallet descriptor
b01 listdescriptors

# 3- Save Wallet Descriptor
wl="tr(m=[..."

cat $wl > ./tr

# 4- Generate Wallet
btc-cold create ./tr ./tr.wallet

# 5- Generate Address
btc-cold address ./tr.wallet

# 6- Construct PSBT
btc-cold construct ./tr.wallet ./psbt.rgb 1000 --input "$txid:$vout /0/0 rbf" -e $electrum_host -p $electrum_port
```