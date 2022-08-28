# Docker setup for LNPBP Nodes (Bitcoin, LNP & RGB) in regtest mode

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

# Load Commands
source .commands
```

### Install Dependencies

### _Install Wallet Descriptor and DBC_
```bash
cargo install descriptor-wallet --version "0.8.2" --all-features --locked
cargo install bp-core --version "0.8.0"  --all-features --locked
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

# 6- Send coins to Issue Address (After Create Wallets**)
$issueaddr="tb1..."
b01 sendtoaddress $issueaddr 0.001
b01 generatetoaddress 10 $(echo $addr1)

# 7- Send coins to change Address (After Create Wallets**)
$changeaddr="tb1..."
b01 sendtoaddress $changeaddr 0.001
b01 generatetoaddress 10 $(echo $addr1)

# 8- Send coins to Receive Address (After Create Wallets**)
$receiveaddr="tb1..."
b01 sendtoaddress $receiveaddr 0.0001
b01 generatetoaddress 10 $(echo $addr1)
```

### _Running APPs_


### _Running L2_

```bash
# 1- Generate funding wallet
lnpd1 init # tprv8gD6szk1Vr8Bm3dY4wpxodYwkZihHM8XLWypXiUTcuQamaMwUHKDoJZJfjY3kCCzRe9PUmeWz3UtQtPJnbJsykoarXpQrgNqu2vXUcydtR2
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
lnp01 connect "bifrost://$pb@$lnp2_ip:$lnp2_port"

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

ticker="USDT"
name="Tether Stablecoin"
amount="1000"
allocation="$amount@$txid:$vout"

fungible1 issue "$ticker" "$name" "$allocation"
# Output=> $contractID="rgb1..."
# Output=> $contract="rgbc1..."

# 2- Sync Contract
rgb01 contract register $contract

# 3- Create Blind UTXO
receive_txid='...' #example (receive address transaction)
receive_vout='...' #example (receive address vout)

rgbstd1 blind $receive_txid:$receive_vout
seal_definition="txob..."
blind_factor="..."
```

### _Create and Send Consignment_
```bash
# 1- Prepare Consignment (State Transfer)
rgb01 transfer compose $contractID $txid:$vout /var/lib/rgb/fungible.rgbc
rgbstd1 consignment validate /var/lib/rgb/fungible.rgbc "$electrum_host:$electrum_port"

# 2- Prepare to Transfer Change
change_txid='...' #example (change address transaction)
change_vout='...' #example (change address vout)

atomic_value=990
change_value="$atomic_value@tapret1st:$change_txid:$change_vout"
spent_value="10@$seal_definition"

fungible1 transfer --utxo "$txid:$vout" --change $change_value /var/lib/rgb/fungible.rgbc $spent_value /var/lib/rgb/fungible.rgbt

# 3- Transfer Asset (After Create PSBT**)
# docker cp ./wallets/fungible.psbt [DOCKER_CONTAINER_ID]:/var/lib/rgb/  <--- for docker noobs =)
rgb01 contract embed $contractID /var/lib/rgb/fungible.psbt
rgb01 transfer combine $contractID /var/lib/rgb/fungible.rgbt /var/lib/rgb/fungible.psbt "$txid:$vout"

# 4- Check PSBT Transfer
rgbstd1 psbt bundle /var/lib/rgb/fungible.psbt
rgbstd1 psbt analyze /var/lib/rgb/fungible.psbt

# 5- Make a Transfer
rgb01 transfer finalize --endseal $seal_definition /var/lib/rgb/fungible.psbt /var/lib/rgb/fungible.rgbc --send "$pb@$lnp1_ip:$lnp1_port" 
rgbstd1 consignment validate /var/lib/rgb/fungible.rgbc "$electrum_host:$electrum_port"

# 6- Check Transfer (After Sign PSBT**)
rgbstd1 consignment validate /var/lib/rgb/fungible.rgbc "$electrum_host:$electrum_port"

# 7- Consume Transfer
rgb01 transfer consume /var/lib/rgb/fungible.rgbc
rgb02 transfer consume /var/lib/rgb/fungible.rgbc

# 8- Accept Transfer
```

### _Bonus: Create Wallets_

```bash
# 1- Generate seed and private key
btc-hot seed -P ./wallets/regtest.seed
btc-hot seed -P ./wallets/regtest.seed2

# 2- Save Wallet Descriptors
btc-hot derive --testnet --scheme bip86 -P ./wallets/regtest.seed ./wallets/regtest.tr
btc-hot derive --testnet --scheme bip86 -P ./wallets/regtest.seed2 ./wallets/regtest.tr2

wl="tr(m=[..."
wl2="tr(m=[..."

echo $wl > ./wallets/regtest.desc
echo $wl2 > ./wallets/regtest.desc2

# 3- Generate Wallets
btc-cold create --regtest ./wallets/regtest.desc ./wallets/regtest.wallet -e $electrum_host -p $electrum_port
btc-cold create --regtest ./wallets/regtest.desc2 ./wallets/regtest.wallet2 -e $electrum_host -p $electrum_port

# 4- Get Issue and Change Address
btc-cold address ./wallets/regtest.wallet -e $electrum_host -p $electrum_port
issueaddr="tb1p..."
changeaddr="tb1p..."

# 5- Get Receive Address
btc-cold address ./wallets/regtest.wallet2  -e $electrum_host -p $electrum_port
receiveaddr="tb1p..."
```

### _Bonus: Create PSBT_

```bash
# 1- Construct PSBT (Retrieve UTXO)
fee=1000
change_addr="$issueaddr:99000" # Avoid "burn bitcoin" (PROVABLY_UNSPENDABLE problem)
btc-cold check ./wallets/regtest.wallet -e $electrum_host -p $electrum_port
btc-cold construct --input "$txid:$vout /0/0" --allow-tapret-path 1 ./wallets/regtest.wallet ./wallets/fungible.psbt -e $electrum_host -p $electrum_port $fee --output $change_addr
```

### _Bonus: Sign and Publish PSBT_

```bash
# 1- Sign PSBT
# docker cp [DOCKER_CONTAINER_ID]:/var/lib/rgb/fungible.psbt ./wallets/fungible.sign    <--- for docker noobs =)
btc-hot sign ./wallets/fungible.sign ./wallets/regtest.tr

# 2- Send PSBT transaction
btc-cold finalize --publish regtest ./wallets/fungible.sign -e $electrum_host -p $electrum_port

```