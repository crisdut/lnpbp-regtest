# Docker setup for Satoshi Racer RGB Integration (Bitcoin, LNP, BP & RGB) in regtest mode

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
docker build . -t stk-sr/lnp:0.5.0-slim
docker build . -t stk-sr/rgb:0.4.0-slim
docker build . -t stk-sr/electrs:0.9.0-alpine
docker build . -t stk-sr/bitcoin:22.0-alpine

# Command Alias (Docker)
alias rgbli="docker-compose exec rgb-node rgb-cli --network=regtest --data-dir=/var/lib/rgb/"
alias lncli="docker-compose exec lnp-node lnp-cli"
alias bcli="docker-compose exec bitcoin bitcoin-cli -chain=regtest -rpcconnect=localhost -rpcport=18889 -rpcuser=bitcoin -rpcpassword=bitcoin"

alias lnpd="docker-compose run --rm lnp-node --network=regtest --electrum-port=50001 --electrum-server=electrs"
alias rgbd="docker-compose run --rm rgb-node --network=regtest --bin-dir=/usr/local/bin/ --data-dir=/var/lib/rgb/ --electrum=electrs:50001"

# Update rust
rustup component add rust-src --toolchain nightly

# Generate private key (libbitcoin)
bx seed -b 128 | bx mnemonic-new | bx mnemonic-to-seed -p "" | bx hd-new
```
