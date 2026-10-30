![(22)](https://github.com/okannako/celestiamochascript/assets/73176377/f005e199-f5f9-4002-a444-e683baa2f01b)

The Celestia Mocha Testnet has been running for a very long time and kept running without interruption after Mainnet. The Celestia team continues its development on this network. The network is currently running as mocha-5 (validators from mocha-4 were not migrated and need to be created again on mocha-5). Below is the command for the script I created. When you run it, you can choose the node you want to install from the options and have it set up in a very short time. Besides Validator, Fibre, Bridge and Light Node installation, there are also options for other operations. The script is based on the current releases (celestia-app v10.5.0-mocha, celestia-node v0.34.4-mocha).

NOTE: The Full Storage Node type has been removed from celestia-node. If you want to keep all data, run a Bridge Node with --archival.

```
curl -s https://raw.githubusercontent.com/okannako/celestiamochascript-en/refs/heads/main/nodescript.sh > nodescript.sh && chmod +x nodescript.sh && ./nodescript.sh
```

### Enabling bbr (Required)
- The script does this automatically during the Validator setup. If you installed a Bridge or Light Node, or want to check it, run the commands below.
```
cd $HOME/celestia-app
make bbr-enable
make bbr-check
```

- If you get an error with the commands above, you can enable it with the commands below.
```
sudo modprobe tcp_bbr
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

- To check that it is active, run the command below. The result should be `bbr`.
```
sysctl net.ipv4.tcp_congestion_control | awk '{print $3}'
```

If you have any questions during or after setup, you can reach me via Telegram, Mail or Discord.
