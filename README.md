# Sui Fullnode
Mysten-labs Sui quick installer

# Requirement
- CPU : 2 cores
- Memory : 8GiB RAM
- Storage: 50GB SSD
- OS : Ubuntu version 18.04 (Bionic Beaver)

Storage requirements will vary based on various factors (age of the chain, transaction rate, etc) although we don't anticipate running a fullnode on devnet will require more than 50 GBs today given it is reset upon each release roughly every two weeks.

# Installation
## Prerequisites
- Create Github account
- Fork Mystenlabs/sui repository (https://github.com/MystenLabs/sui)

## install
```bash
wget -O install-sui-fullnode.sh https://raw.githubusercontent.com/qyeah98/sui-installer/main/install-sui-fullnode.sh
chmod +x install-sui-fullnode.sh
./install-sui-fullnode.sh
```

### input your forked sui repository url

```bash
INPUT your github url: 

# Example
INPUT your github url: https://github.com/qyeah98/sui
```

### input y if you want to open Sui JSON RPC Port
```bash
Open Sui-JSON-RPC Port. OK ? (y/N): 

# Example
Open Sui-JSON-RPC Port. OK ? (y/N): y
```

### input y if you want to open Sui Metrics Port
```bash
Open Metrics Port. OK ? (y/N): 

# Example
Open Metrics Port. OK ? (y/N): y
```


## Info
### View sui-node logs
```bash
journalctl -u suid -f -o cat
```

### Call Sui JSON RPC API
```bash
curl -s -X POST http://127.0.0.1:9000 -H 'Content-Type: application/json' -d '{ "jsonrpc":"2.0", "method":"rpc.discover","id":1}' | jq .result.info
```

You can more info about here.
[Sui JSON-RPCAPI](../build/json-rpc.md#sui-json-rpc-api)

### Stop node
```bash
sudo systemctl stop suid
```

### Restart node
```bash
sudo systemctl restart suid
```

### Delete node
```bash
sudo systemctl stop suid
sudo systemctl disable suid
rm -rf ~/sui /var/sui/
rm /etc/systemd/suid.service
```

### Update node
```bash
# Stop sui-node
sudo systemctl stop suid

# Remove old db
rm -rf /var/sui/db /var/sui/genesis.blob

# Fetch the source from the latest release
git checkout -B devnet --track upstream/devnet

# Reset your branch:
git fetch upstream

# Download latest genesis.blob
wget -O /var/sui/genesis.blob https://github.com/MystenLabs/sui-genesis/raw/main/devnet/genesis.blob

# Restart your Sui fullnode
cargo build --release -p sui-node
mv ~/sui/target/release/sui-node /usr/local/bin/

sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable suid
sudo systemctl restart suid
```

# Reference
https://github.com/MystenLabs/sui/blob/main/doc/src/build/fullnode.md
`
