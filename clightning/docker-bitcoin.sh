BITCOIN_VERSION="22.0"
BITCOIN_TARBALL="bitcoin-${BITCOIN_VERSION}-${aarch64:-`uname -m`}-linux-gnu.tar.gz"
BITCOIN_URL="https://bitcoincore.org/bin/bitcoin-core-$BITCOIN_VERSION/$BITCOIN_TARBALL"

BITCOIN_ASC_URL="https://bitcoincore.org/bin/bitcoin-core-$BITCOIN_VERSION/SHA256SUMS.asc"

echo "Extract and verify"
wget -qO $BITCOIN_TARBALL $BITCOIN_URL
wget -qO bitcoin.asc "$BITCOIN_ASC_URL"
grep $BITCOIN_TARBALL bitcoin.asc | tee SHA256SUMS.asc
sha256sum -c SHA256SUMS.asc
BD=bitcoin-$BITCOIN_VERSION/bin
tar -xzvf $BITCOIN_TARBALL $BD/bitcoin-cli --strip-components=1
echo "Showing current working directory"
pwd
echo "Showing whats in current working directory"
ls -la
echo "Showing whats in $PWD/bin"
ls -la bin/
echo "Cleaning up"
rm $BITCOIN_TARBALL
