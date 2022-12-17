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
* RGB Node v0.8.1
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

# 6- Send coins to Issue Address (After Create Wallets**)
$issueaddr="bcrt1..."
b01 sendtoaddress $issueaddr 0.001

# 7- Send coins to change Address (After Create Wallets**)
$changeaddr="bcrt1..."
b01 sendtoaddress $changeaddr 0.001

# 8- Send coins to Receive Address (After Create Wallets**)
$receiveaddr="bcrt1..."
b01 sendtoaddress $receiveaddr 0.0001
b01 generatetoaddress 1 $(echo $addr1)
```

### _Running APPs_


### _Running L2_

```bash
# 1- Generate funding wallet
lnpd1 init # tprv8gD6szk1Vr8Bm3dY4wpxodYwkZihHM8XLWypXiUTcuQamaMwUHKDoJZJfjY3kCCzRe9PUmeWz3UtQtPJnbJsykoarXpQrgNqu2vXUcydtR2
lnpd2 init # tprv8ZgxMBicQKsPdXjTY8BuF4WPhEhfGELSMiZM1XfLNcR2hka3wTKPqakbpMDHedYaRBJwPBeADqRnGPNHGCuqk9FUVmj5fJrzvbnoQPoTTTN

# 2- Up and running nodes
docker-compose up -d lnp1 lnp2 cln1 cln2

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

### _Create Asset_

```bash
# 1- Get Issue Outpoint
txid='...' #example (issuer transaction)
vout='...' #example (issuer vout)

# 2.a - Generate a Fungible Token
ticker="RGB20"
name="The Most Honest Token"
amount="1000"
allocation="$amount@$txid:$vout"

fungible1 issue "$ticker" "$name" "$allocation"

# 2.b - Generate a Collectible Token
ticker="RGB21"
name="The Most Honest NFT"
amount="1"
allocation="$amount@$txid:$vout"

collectible1 issue "$ticker" "$name" "$allocation"
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
lnp_storm_ip=172.20.0.20
lnp_storm_port=64964
rgb01 transfer finalize --endseal $seal_definition /var/lib/rgb/fungible.psbt /var/lib/rgb/fungible.rgbc --send "$pb2@$lnp_storm_ip:$lnp_storm_port"
rgbstd1 consignment validate /var/lib/rgb/fungible.rgbc "$electrum_host:$electrum_port"

# 6- Check Transfer (After Sign PSBT**)
b01 generatetoaddress 1 $(echo $addr1)
rgbstd1 consignment validate /var/lib/rgb/fungible.rgbc "$electrum_host:$electrum_port"

# 7- Consume Transfer
rgb01 transfer consume /var/lib/rgb/fungible.rgbc

# 8- Reveal Transfer
rgb02 transfer consume /var/lib/rgb/fungible.rgbc --reveal "tapret1st@$receive_txid:$receive_vout#$blind_factor"
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
btc-cold create ./wallets/regtest.desc ./wallets/regtest.wallet -e $electrum_host -p $electrum_port
btc-cold create ./wallets/regtest.desc2 ./wallets/regtest.wallet2 -e $electrum_host -p $electrum_port

# 4- Get Issue and Change Address
btc-cold address --regtest ./wallets/regtest.wallet -e $electrum_host -p $electrum_port
issueaddr="bcrt1..."
changeaddr="bcrt1..."

# 5- Get Receive Address
btc-cold address --regtest ./wallets/regtest.wallet2  -e $electrum_host -p $electrum_port
receiveaddr="bcrt1..."
```

### _Bonus: Create PSBT_

```bash
# 1- Construct PSBT (Retrieve UTXO)
fee=1000
btc-cold construct --input "$txid:$vout /0/0" --allow-tapret-path 1 ./wallets/regtest.wallet ./wallets/fungible.psbt -e $electrum_host -p $electrum_port $fee
```

### _Bonus: Sign and Publish PSBT_

```bash
# 1- Sign PSBT
# docker cp [DOCKER_CONTAINER_ID]:/var/lib/rgb/fungible.psbt ./wallets/fungible.sign    <--- for docker noobs =)
btc-hot sign ./wallets/fungible.sign ./wallets/regtest.tr

# 2- Send PSBT transaction
btc-cold finalize --publish regtest ./wallets/fungible.sign -e $electrum_host -p $electrum_port
```