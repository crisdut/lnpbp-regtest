# Docker setup for Satoshi Racer RGB Integration (Bitcoin, LNP, BP & RGB) in regtest mode

### ONLY FOR DEVELOPMENT and TESTING. These tools may not be suitable for production deployments.

### Notes & prerequisites
 - `docker` and `docker-compose` installation is required (https://docs.docker.com/install/).
 - `jq` tool is used in examples for parsing json responses.
 - All nodes will sync to chain after the first Bitcoin regtest blocks are generated.
 - Ports and other daemon configuration can be changed in the `.env` and `docker-compose.yml` files.

 ### Instructions
 - Generate a individual docker image to each node. 