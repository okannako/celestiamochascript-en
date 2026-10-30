#!/bin/bash
echo -e "\033[0;37m"
echo "============================================================================================================"
echo " #####   ####        ####        ####  ####    ######    ##########  ####    ####  ###########   ####  ####"
echo " ######  ####       ######       #### ####    ########   ##########  ####    ####  ####   ####   #### ####"
echo " ####### ####      ###  ###      ########    ####  ####     ####     ####    ####  ####   ####   ########"
echo " #### #######     ##########     ########   ####    ####    ####     ####    ####  ###########   ########"
echo " ####  ######    ############    #### ####   ####  ####     ####     ####    ####  ####  ####    #### ####"
echo " ####   #####   ####      ####   ####  ####   ########      ####     ############  ####   ####   ####  ####"
echo " ####    ####  ####        ####  ####   ####    ####        ####     ############  ####    ####  ####   ####"
echo "============================================================================================================"
echo -e '\e[36mTwitter :\e[39m' https://twitter.com/TurkNako
echo -e '\e[36mGithub  :\e[39m' https://github.com/okannako
echo -e '\e[36mYoutube :\e[39m' https://www.youtube.com/@CryptoChainNakoTurk
echo -e "\e[0m"
sleep 5

CHAIN_ID="mocha-5"
APP_VERSION="v10.5.0-mocha"
NODE_VERSION="v0.34.4-mocha"
GO_VERSION="1.26.9"
CORE_IP="rpc-mocha.pops.one"
CORE_PORT="9090"

echo -e "\e[1m\e[32m What would you like to do? \e[0m" && sleep 2
PS3='Select an action: '
options=(
"Install Validator Node"
"Check Validator Node"
"Create Validator"
"Install Fibre Server"
"Register Fibre Address On-Chain"
"Install Light Node"
"Install Bridge Node"
"Install Full Storage Node"
"Reset Light Node Data"
"Reset Bridge Node Data"
"Reset Full Storage Node Data"
"Show Light Node ID"
"Show Bridge Node ID"
"Show Full Storage Node ID"
"Exit")
select opt in "${options[@]}"
do
case $opt in

"Install Validator Node")

echo -e "\e[1m\e[32m Updates \e[0m" && sleep 2

sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git ncdu lz4 -y
sudo apt install make -y
sleep 1

echo -e "\e[1m\e[32m Installing Go \e[0m" && sleep 2
ver="$GO_VERSION"
cd $HOME
wget "https://go.dev/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
go version && sleep 2

cd $HOME
rm -rf celestia-app
git clone https://github.com/celestiaorg/celestia-app.git
cd celestia-app/
git checkout tags/$APP_VERSION -b $APP_VERSION
make install
celestia-appd version && sleep 3

echo -e "\e[1m\e[32m Enabling bbr \e[0m" && sleep 2
make bbr-enable
cd $HOME

echo "Node name (moniker):"
read NodeName
echo export NodeName=${NodeName} >> $HOME/.bash_profile

celestia-appd init "$NodeName" --chain-id $CHAIN_ID

celestia-appd download-genesis $CHAIN_ID

SEEDS=$(curl -sL https://raw.githubusercontent.com/celestiaorg/networks/main/mocha-5/seeds.txt | tr '\n' ',' | sed 's/,$//')
PEERS=$(curl -sL https://raw.githubusercontent.com/celestiaorg/networks/main/mocha-5/peers.txt | tr '\n' ',' | sed 's/,$//')
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.celestia-app/config/config.toml

sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.celestia-app/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.celestia-app/config/app.toml

sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.002utia"|g' $HOME/.celestia-app/config/app.toml

# gRPC and signer for the Fibre server (127.0.0.1 only, never exposed)
sed -i -e '/^\[grpc\]/,/^\[/{s/^enable *=.*/enable = true/; s/^address *=.*/address = "127.0.0.1:9090"/}' $HOME/.celestia-app/config/app.toml
sed -i -e 's/^priv_validator_grpc_laddr *=.*/priv_validator_grpc_laddr = "127.0.0.1:26669"/' $HOME/.celestia-app/config/config.toml

celestia-appd tendermint unsafe-reset-all --home $HOME/.celestia-app

sudo tee <<EOF >/dev/null /etc/systemd/system/celestia-appd.service
[Unit]
Description=Celestia node
After=network-online.target
[Service]
User=root
ExecStart=$(which celestia-appd) start --home $HOME/.celestia-app
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable celestia-appd
sudo systemctl start celestia-appd

echo "Wallet name:"
read WalletName
echo export WalletName=${WalletName} >> $HOME/.bash_profile
celestia-appd keys add $WalletName

echo -e '\e[36mYour wallet details are shown in this step. >>>PLEASE BACK UP YOUR MNEMONIC (SECRET WORDS).<<< Press Enter to continue after backing them up.\e[39m'
read Enter

echo -e '\e[36mIMPORTANT: Wait until the node syncs to the latest block. To check, run the script again and choose the related option.\e[39m'
sleep 7
sudo journalctl -u celestia-appd -f

break
;;

"Check Validator Node")

celestia-appd status 2>&1 | jq .sync_info
echo -e '\e[36mIMPORTANT: When "catching_up" is false, your node has reached the latest block and you can run the script again to Create Validator. Don't forget to get test tokens to your wallet before creating the validator: type $request YOUR_WALLET_ADDRESS in the #mocha-faucet channel on Discord, or use https://mocha.celenium.io/faucet\e[39m'
sleep 10

break
;;

"Create Validator")

source $HOME/.bash_profile

celestia-appd tx staking create-validator \
--amount=1000000utia \
--pubkey=$(celestia-appd tendermint show-validator) \
--moniker=$NodeName \
--chain-id=$CHAIN_ID \
--commission-rate=0.05 \
--commission-max-rate=0.20 \
--commission-max-change-rate=0.01 \
--min-self-delegation=1 \
--from=$WalletName \
--gas-adjustment=1.4 \
--gas=auto \
--gas-prices=0.01utia

echo -e '\e[36mIMPORTANT: After creating the validator, make sure to back up the config folder inside .celestia-app.\e[39m'
sleep 10

break
;;

"Install Fibre Server")

echo -e "\e[1m\e[32m Installing Fibre \e[0m" && sleep 2

APP_V=$(curl -s http://127.0.0.1:26657/abci_info | jq -r .result.response.app_version)
if [ "$APP_V" -lt 10 ] 2>/dev/null; then
echo -e '\e[31mERROR: v10 is not active on-chain yet or the node is not running. The validator node must be installed and synced first.\e[39m'
break
fi

echo "Folder for Fibre data (preferably on a different disk than celestia-app, default: /data/fibre):"
read FIBRE_HOME
FIBRE_HOME=${FIBRE_HOME:-/data/fibre}
echo export FIBRE_HOME=${FIBRE_HOME} >> $HOME/.bash_profile
sudo mkdir -p $FIBRE_HOME

cd $HOME
wget https://github.com/celestiaorg/celestia-app/releases/download/$APP_VERSION/fibre_Linux_x86_64.tar.gz
wget https://github.com/celestiaorg/celestia-app/releases/download/$APP_VERSION/checksums.txt
sha256sum --ignore-missing --check checksums.txt
tar -xzf fibre_Linux_x86_64.tar.gz
sudo mv fibre /usr/local/bin/
rm fibre_Linux_x86_64.tar.gz checksums.txt
fibre version && sleep 3

sudo tee <<EOF >/dev/null /etc/systemd/system/fibre.service
[Unit]
Description=Celestia Fibre server
After=network-online.target celestia-appd.service
[Service]
User=root
ExecStart=/usr/local/bin/fibre start --home $FIBRE_HOME --app-grpc-address 127.0.0.1:9090 --signer-grpc-address 127.0.0.1:26669 --server-listen-address 0.0.0.0:7980
Restart=on-failure
RestartSec=5
TimeoutStopSec=120
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable fibre
sudo systemctl start fibre

echo -e '\e[36mIMPORTANT: Port 7980 must be reachable from the internet (sudo ufw allow 7980/tcp). Never expose ports 9090 and 26669. Once Fibre is running, run the script again and choose "Register Fibre Address On-Chain".\e[39m'
sleep 7
sudo journalctl -u fibre -f

break
;;

"Register Fibre Address On-Chain")

source $HOME/.bash_profile

echo "Your server's public IP address or domain:"
read FIBRE_HOST

celestia-appd tx valaddr set-host $FIBRE_HOST:7980 \
--from=$WalletName \
--chain-id=$CHAIN_ID \
--gas-adjustment=1.4 \
--gas=auto \
--gas-prices=0.01utia

sleep 10
echo -e '\e[36mRegistration check (should show found: true):\e[39m'
celestia-appd query valaddr provider $(celestia-appd comet show-address)

break
;;

"Install Light Node")

echo -e "\e[1m\e[32m Updates \e[0m" && sleep 2
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git ncdu -y
sudo apt install make -y
sleep 1

echo -e "\e[1m\e[32m Installing Go \e[0m" && sleep 2
ver="$GO_VERSION"
cd $HOME
wget "https://go.dev/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
go version && sleep 2

cd $HOME
rm -rf celestia-node
git clone https://github.com/celestiaorg/celestia-node.git
cd celestia-node/
git checkout tags/$NODE_VERSION
make build
make install
make cel-key
celestia version && sleep 3
celestia light init --p2p.network mocha

echo -e '\e[36mYour wallet details are shown in this step. >>>PLEASE BACK UP YOUR MNEMONIC (SECRET WORDS).<<< Press Enter to continue after backing them up.\e[39m'
read Enter

sudo tee <<EOF >/dev/null /etc/systemd/system/celestia-lightd.service
[Unit]
Description=celestia-light Cosmos daemon
After=network-online.target

[Service]
User=root
ExecStart=/usr/local/bin/celestia light start --core.ip $CORE_IP --core.port $CORE_PORT --keyring.backend test --keyring.keyname my_celes_key --p2p.network mocha
Restart=on-failure
RestartSec=3
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable celestia-lightd
sudo systemctl start celestia-lightd

echo -e '\e[36mIMPORTANT: Back up the /root/.celestia-light-mocha-5/keys folder.\e[39m'
sleep 7

journalctl -u celestia-lightd.service -f

break
;;

"Install Bridge Node")

echo -e "\e[1m\e[32m Updates \e[0m" && sleep 2
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git ncdu -y
sudo apt install make -y
sleep 1

echo -e "\e[1m\e[32m Installing Go \e[0m" && sleep 2
ver="$GO_VERSION"
cd $HOME
wget "https://go.dev/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
go version && sleep 2

cd $HOME
rm -rf celestia-node
git clone https://github.com/celestiaorg/celestia-node.git
cd celestia-node/
git checkout tags/$NODE_VERSION
make build
make install
make cel-key
celestia version && sleep 3

echo "Node name (moniker):"
read NodeName
echo export NodeName=${NodeName} >> $HOME/.bash_profile

echo "IP address of your own consensus node (leave empty to use $CORE_IP):"
read MY_CORE_IP
BRIDGE_CORE_IP=${MY_CORE_IP:-$CORE_IP}

celestia bridge init --core.ip $BRIDGE_CORE_IP --core.port $CORE_PORT --p2p.network mocha

sudo tee /etc/systemd/system/celestia-bridge.service > /dev/null <<EOF
[Unit]
Description=celestia-bridge Cosmos daemon
After=network-online.target

[Service]
User=root
ExecStart=/usr/local/bin/celestia bridge start --core.ip $BRIDGE_CORE_IP --core.port $CORE_PORT --keyring.backend test --keyring.keyname my_celes_key --p2p.network mocha
Restart=on-failure
RestartSec=3
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable celestia-bridge
sudo systemctl start celestia-bridge

echo -e '\e[36mIMPORTANT: Back up the /root/.celestia-bridge-mocha-5/keys folder. Port 2121 must be open so other nodes can find you (sudo ufw allow 2121).\e[39m'
sleep 7

sudo journalctl -u celestia-bridge.service -f

break
;;

"Install Full Storage Node")

echo -e '\e[31mINFO: The full storage node type has been removed from celestia-node. Only bridge and light nodes remain. If you want to keep all data, install a bridge node and add --archival to the end of the start command in its service file.\e[39m'
sleep 10

break
;;

"Reset Light Node Data")

sudo systemctl stop celestia-lightd
celestia light unsafe-reset-store --p2p.network mocha
sudo systemctl restart celestia-lightd
journalctl -u celestia-lightd.service -f

break
;;

"Reset Bridge Node Data")

sudo systemctl stop celestia-bridge
celestia bridge unsafe-reset-store --p2p.network mocha
sudo systemctl restart celestia-bridge
sudo journalctl -u celestia-bridge.service -f

break
;;

"Reset Full Storage Node Data")

echo -e '\e[31mINFO: The full storage node type has been removed. To fully remove your old full node: sudo systemctl stop celestia-fulld && sudo systemctl disable celestia-fulld && rm -rf $HOME/.celestia-full-mocha-4\e[39m'
sleep 10

break
;;

"Show Light Node ID")

AUTH_TOKEN=$(celestia light auth admin --p2p.network mocha)

curl -X POST \
     -H "Authorization: Bearer $AUTH_TOKEN" \
     -H 'Content-Type: application/json' \
     -d '{"jsonrpc":"2.0","id":0,"method":"p2p.Info","params":[]}' \
     http://localhost:26658

break
;;

"Show Bridge Node ID")

AUTH_TOKEN=$(celestia bridge auth admin --p2p.network mocha)

curl -X POST \
     -H "Authorization: Bearer $AUTH_TOKEN" \
     -H 'Content-Type: application/json' \
     -d '{"jsonrpc":"2.0","id":0,"method":"p2p.Info","params":[]}' \
     http://localhost:26658

break
;;

"Show Full Storage Node ID")

echo -e '\e[31mINFO: The full storage node type has been removed. If you run a bridge node, choose "Show Bridge Node ID".\e[39m'
sleep 5

break
;;

"Exit")
exit
;;
*) echo "invalid option";;
esac
done
