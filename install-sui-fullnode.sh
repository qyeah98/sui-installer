#!/bin/bash

echo "=================================================="
echo -e "\033[0;35m"
echo "                             .__      ";
echo "   _________.__. ____ _____  |  |__   ";
echo "  / ____<   |  |/ __ \\__  \ |  |  \  ";
echo " < <_|  |\___  \  ___/ / __ \|   Y  \ ";
echo "  \__   |/ ____|\___  >____  /___|  / ";
echo "     |__|\/         \/     \/     \/  ";
echo "                                      ";
echo -e "\e[0m"
echo "=================================================="

sleep 1

echo -e "\e[1m\e[32m1. Set FullNode Parameter \e[0m" && sleep 1

echo -e "\e[1m\e[32m1.1 Set Github URL \e[0m" && sleep 1

while :
do
  read -p "INPUT your github url: " URLGITHUB
  if [ -n "$URLGITHUB" ]; then
    break
  fi
done

echo -e "\e[1m\e[32m1.2 Open Sui-JSON-PRC Port \e[0m" && sleep 1
read -p "Open Sui-JSON-RPC Port. OK ? (y/N): " yn
OPENRPC=true
case "$yn" in [yY]*) ;; *) OPENRPC=false  ; continue ;; esac

echo -e "\e[1m\e[32m1.3 Open Metrics Port \e[0m" && sleep 1
read -p "Open Metrics Port. OK ? (y/N): " yn
OPENMETRICS=true
case "$yn" in [yY]*) ;; *) OPENMETRICS=false  ; continue ;; esac

if exists curl; then
	echo ''
else
  sudo apt update && sudo apt install curl -y < "/dev/null"
fi

echo "=================================================="
echo -e "\e[1m\e[32m2. Prerequisites for Ubuntu\e[0m" && sleep 1


bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi

apt-get update && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y --no-install-recommends tzdata git ca-certificates curl build-essential libssl-dev pkg-config libclang-dev cmake

echo "=================================================="
echo -e "\e[1m\e[32m3. Install Rust\e[0m" && sleep 1
sudo curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env

echo "=================================================="
echo -e "\e[1m\e[32m4. Clone fork of the Sui repository\e[0m" && sleep 1

mkdir -p /var/sui/db
rm -rf /var/sui/db /var/sui/genesis.blob

cd $HOME
git clone $URLGITHUB

cd sui
git remote add upstream https://github.com/MystenLabs/sui
git fetch upstream
git checkout --track upstream/devnet
cp crates/sui-config/data/fullnode-template.yaml /var/sui/fullnode.yaml

echo "=================================================="
echo -e "\e[1m\e[32m5. Download latest genesis.blob\e[0m" && sleep 1

wget -O /var/sui/genesis.blob https://github.com/MystenLabs/sui-genesis/raw/main/devnet/genesis.blob

echo "=================================================="
echo -e "\e[1m\e[32m6. Change fullnode.yaml configuration\e[0m" && sleep 1

sed -i.bak "s/db-path:.*/db-path: \"\/var\/sui\/db\"/ ; s/genesis-file-location:.*/genesis-file-location: \"\/var\/sui\/genesis.blob\"/" /var/sui/fullnode.yaml

if "${OPENRPC}"; then
    sed -e 's/"127.0.0.1:9000"/"0.0.0.0:9000"/g' -i /var/sui/fullnode.yaml
fi

if "${OPENMETRICS}"; then
    sed -e 's/"127.0.0.1:9184"/"0.0.0.0:9184"/g' -i /var/sui/fullnode.yaml
fi

echo "=================================================="
echo -e "\e[1m\e[32m7. Start your Sui fullnode\e[0m" && sleep 1

cargo build --release -p sui-node
mv ~/sui/target/release/sui-node /usr/local/bin/


echo "[Unit]
Description=Sui Node
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=/usr/local/bin/sui-node --config-path /var/sui/fullnode.yaml
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target" > $HOME/suid.service

mv $HOME/suid.service /etc/systemd/system/

sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF

echo "=================================================="
echo -e "\e[1m\e[32m8. Restart Sui fullnode\e[0m" && sleep 1

sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable suid
sudo systemctl restart suid

echo "=================================================="
echo -e "\e[1m\e[32m9. Info\e[0m" && sleep 1
if [[ `service suid status | grep active` =~ "running" ]]; then
  echo -e "Your Sui Node \e[32minstalled and works\e[39m!"
  echo -e "You can check node status by the command \e[7mservice suid status\e[0m"
  IP=curl inet-ip.info
  
  echo -e "Write down \e[32m$IP:9000\e[39m at #📋・node-ip-application"
  
  echo -e "\e[31m [Restart Node] \e[39m"
  echo -e "\e[1m\e[39msudo systemctl restart suid\e[0m"

  echo -e "\e[31m [Stop Node] \e[39m"
  echo -e "\e[1m\e[39msudo systemctl stop suid\e[0m"
  journalctl -u suid -f -o cat

else
  echo -e "Your Sui Node \e[31mwas not installed correctly\e[39m, please reinstall."

  echo -e "\e[31m [Delete Node] \e[39m"
  echo -e "\e[1m\e[39msudo systemctl stop suid\e[0m"
  echo -e "\e[1m\e[39msudo systemctl disable suid\e[0m"
  echo -e "\e[1m\e[39mrm -rf ~/sui /var/sui/\e[0m"
  echo -e "\e[1m\e[39mrm /etc/systemd/suid.service\e[0m"

  echo -e "\e[31m [Install Node] \e[39m"
  echo -e "\e[1m\e[39m./install-sui-fullnode.sh\e[0m"
fi
echo "=================================================="
