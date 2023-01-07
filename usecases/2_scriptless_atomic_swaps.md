### _Scriptless Atomic Swaps_

Based on RGB workgroup discussion:
https://github.com/orgs/LNP-BP/discussions/125

### _Create Asset_

```bash
# 1- Send Coins
b01 sendtoaddress $bobaddr 0.01
b01 sendtoaddress $bobcaddr 0.01
b01 sendtoaddress $aliceaddr 0.01
b01 sendtoaddress $alicecaddr 0.01
b01 generatetoaddress 1 $(echo $addr1)

# 2 - Generate a Coin
ticker="WBTC"
name="Bitcoin Wrapper"
amount="1000"
allocation="$amount@$bob_txid:$bob_vout"

fungible1 issue "$ticker" "$name" "$allocation"

# 3 - Generate a Collectible
ticker="RGB121"
name="NFT"
amount="1"
allocation="$amount@$alice_txid:$alice_vout"

collectible1 issue "$ticker" "$name" "$allocation"

# 4- Sync Contracts
rgb01 contract register $contractB
rgb01 contract register $contractA

# 5- Create Blind UTXO
rgbstd1 blind $bob_change_txid:$bob_change_vout
bob_seal="txob..."
bob_reveal="..."

rgbstd1 blind $alice_change_txid:$alice_change_vout
alice_seal="txob..."
alice_reveal="..."
```

### _Create and Join PSBTs_

```bash
# 1- Construct Bob PSBT
fee=500
btc-cold construct --input "$bob_txid:$bob_vout /0/0" --allow-tapret-path 1 ./wallets/bob.wallet ./wallets/bob.psbt -e $electrum_host -p $electrum_port $fee

# 2- Construct Alice PSBT
fee=500
btc-cold construct --input "$alice_txid:$alice_vout /0/0" --allow-tapret-path 1 ./wallets/alice.wallet ./wallets/alice.psbt -e $electrum_host -p $electrum_port $fee

# 3- Get Base64 PSBT
bob_psbt64=$(rgbstd1 psbt convert $bob_psbt58 -o base64)
alice_psbt64=$(rgbstd1 psbt convert $alice_psbt58 -o base64)

# 4- Join PSBTs
atomic_psbt64=$(b01 joinpsbts '["'$bob_psbt64'", "'$alice_psbt64'"]')

# 5- Save new PSBT
rgbstd1 psbt save $atomic_psbt64 /var/lib/rgb/atomic.psbt
```

### _Create Transitions_

```bash
# 1- Prepare Consignment (State Transfer)
rgb01 transfer compose $contractIDB $bob_txid:$bob_vout /var/lib/rgb/bob.rgbc
rgb01 transfer compose $contractIDA $alice_txid:$alice_vout /var/lib/rgb/alice.rgbc

rgbstd1 consignment validate /var/lib/rgb/bob.rgbc "$electrum_host:$electrum_port"
rgbstd1 consignment validate /var/lib/rgb/alice.rgbc "$electrum_host:$electrum_port"

# 2- Prepare to Transfer Change
atomic_value=990
change_value="$atomic_value@tapret1st:$bob_change_txid:$bob_change_vout"
spent_value="10@$alice_seal"

fungible1 transfer --utxo "$bob_txid:$bob_vout" /var/lib/rgb/bob.rgbc $spent_value /var/lib/rgb/bob.rgbt --change $change_value

atomic_value=0
change_value="$atomic_value@tapret1st:$alice_change_txid:$alice_change_vout"
spent_value="1@$bob_seal"


collectible1 transfer --utxo "$alice_txid:$alice_vout" /var/lib/rgb/alice.rgbc $spent_value /var/lib/rgb/alice.rgbt --change $change_value

# 3- Transfer Asset (After Create PSBT**)
# docker cp ./wallets/atomic.psbt [DOCKER_CONTAINER_ID]:/var/lib/rgb/  <--- for docker noobs =)
rgb01 contract embed $contractIDB /var/lib/rgb/atomic.psbt
rgb01 contract embed $contractIDA /var/lib/rgb/atomic.psbt

rgb01 transfer combine $contractIDB /var/lib/rgb/bob.rgbt /var/lib/rgb/atomic.psbt "$bob_txid:$bob_vout"
rgb01 transfer combine $contractIDA /var/lib/rgb/alice.rgbt /var/lib/rgb/atomic.psbt "$alice_txid:$alice_vout"

# 4- Check PSBT Transfer
rgbstd1 psbt bundle /var/lib/rgb/atomic.psbt
rgbstd1 psbt analyze /var/lib/rgb/atomic.psbt

# 5- Make a Transfer
rgb01 transfer finalize /var/lib/rgb/atomic.psbt --endseal "$bob_seal:/var/lib/rgb/bob.rgbc" --endseal "$alice_seal:/var/lib/rgb/alice.rgbc"

rgbstd1 consignment validate /var/lib/rgb/bob.rgbc "$electrum_host:$electrum_port"
rgbstd1 consignment validate /var/lib/rgb/alice.rgbc "$electrum_host:$electrum_port"

# 6- Sign the PSBT
# docker cp [DOCKER_CONTAINER_ID]:/var/lib/rgb/atomic.psbt ./wallets/atomic.sign   <--- for docker noobs =)
btc-hot sign ./wallets/atomic.sign ./wallets/alice.tr
btc-hot sign ./wallets/atomic.sign ./wallets/bob.tr

btc-cold finalize --publish regtest ./wallets/atomic.sign -e $electrum_host -p $electrum_port

# 7- Check Transfer
b01 generatetoaddress 1 $(echo $addr1)
rgbstd1 consignment validate /var/lib/rgb/bob.rgbc "$electrum_host:$electrum_port"
rgbstd1 consignment validate /var/lib/rgb/alice.rgbc "$electrum_host:$electrum_port"

# 8- Consume and Reveal Transfer
rgb01 transfer consume /var/lib/rgb/bob.rgbc --reveal "tapret1st@$bob_change_txid:$bob_change_vout#$bob_reveal"
rgb01 transfer consume /var/lib/rgb/alice.rgbc --reveal "tapret1st@$alice_change_txid:$alice_change_vout#$alice_reveal"
```

### _Bonus: Create Wallets_

```bash
# 1- Generate seed and private key
btc-hot seed -P ./wallets/bob.seed
btc-hot seed -P ./wallets/alice.seed

# 2- Save Wallet Descriptors
btc-hot derive --testnet --scheme bip86 -P ./wallets/bob.seed ./wallets/bob.tr
btc-hot derive --testnet --scheme bip86 -P ./wallets/alice.seed ./wallets/alice.tr

wl="tr(m=[..."
wl2="tr(m=[..."

echo $wl > ./wallets/bob.desc
echo $wl2 > ./wallets/alice.desc

# 3- Generate Wallets
btc-cold create ./wallets/bob.desc ./wallets/bob.wallet -e $electrum_host -p $electrum_port
btc-cold create ./wallets/alice.desc ./wallets/alice.wallet -e $electrum_host -p $electrum_port
```
