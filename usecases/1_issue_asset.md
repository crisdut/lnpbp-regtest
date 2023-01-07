### _Create Asset_

```bash
# 1- Send Coins
b01 sendtoaddress $issueraddr 0.01
b01 sendtoaddress $changeaddr 0.01
b01 sendtoaddress $receiveaddr 0.001
b01 generatetoaddress 1 $(echo $addr1)

# 2- Get Issue Outpoint
txid='...' #example (issuer transaction)
vout='...' #example (issuer vout)

# 3 - Generate a Fungible Token
ticker="RGB20"
name="The Most Honest Token"
amount="1000"
allocation="$amount@$txid:$vout"

fungible1 issue "$ticker" "$name" "$allocation"

# 4- Sync Contract
rgb01 contract register $contract

# 5- Create Blind UTXO
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
# TODO: 1-N
fungible1 transfer --utxo "$txid:$vout" /var/lib/rgb/fungible.rgbc $spent_value /var/lib/rgb/fungible.rgbt --change $change_value

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
# TODO: 1-N
rgb01 transfer finalize /var/lib/rgb/fungible.psbt /var/lib/rgb/fungible.rgbc --endseal $seal_definition --send "$pb2@$lnp_storm_ip:$lnp_storm_port"
rgbstd1 consignment validate /var/lib/rgb/fungible.rgbc "$electrum_host:$electrum_port"

# 6- Check Transfer (After Sign PSBT**)
b01 generatetoaddress 1 $(echo $addr1)
rgbstd1 consignment validate /var/lib/rgb/fungible.rgbc "$electrum_host:$electrum_port"

# 7- Consume Transfer
rgb01 transfer consume /var/lib/rgb/fungible.rgbc

# 8- Reveal Transfer
# TODO: 1-N
rgb01 transfer consume /var/lib/rgb/fungible.rgbc --reveal "tapret1st@$receive_txid:$receive_vout#$blind_factor"
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
