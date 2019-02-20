#!/bin/bash

echo "Updating linux packages"
sudo apt-get update -y && apt-get upgrade -y

echo "Installing git"
sudo apt install git -y

echo "Installing curl"
sudo apt-get install curl -y

echo "Intalling fail2ban"
sudo apt install fail2ban -y

echo "Installing Firewall"
sudo apt install ufw -y
ufw default allow outgoing
ufw default deny incoming
ufw allow ssh/tcp
ufw limit ssh/tcp
ufw allow 24055/tcp
ufw logging on
ufw --force enable

echo "Installing PWGEN"
sudo apt-get install -y pwgen

echo "Installing 2G Swapfile"
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

echo "Installing Dependencies"
sudo apt-get --assume-yes install automake build-essential make g++ libboost-all-dev libssl-dev libdb5.3++-dev libminiupnpc-dev libz-dev libcurl4-openssl-dev

#Echo "Grab libdb"
#sudo add-apt-repository ppa:bitcoin/bitcoin -y
#sudo apt-get update -y
#sudo apt-get install libdb4.8-dev libdb4.8++-dev -y

echo "Compiling Swipp Wallet"
git clone https://github.com/teamswipp/swippcore
#cd swippcore/src/leveldb/
#chmod +x build_detect_platform
#make
#make libleveldb.a libmemenv.a
cd ~/swippcore/src
make -f makefile.unix
mv ~/swippcore/src/swippd /usr/local/bin/swippd

echo "Populate swipp.conf"
mkdir ~/.swipp
    # Get VPS IP Address
    VPSIP=$(curl ipinfo.io/ip)
    # create rpc user and password
    rpcuser=$(openssl rand -base64 24)
    # create rpc password
    rpcpassword=$(openssl rand -base64 48)
    echo -n "What is your masternodeprivkey? (Hint:genkey output)"
    read MASTERNODEPRIVKEY
    echo -e "rpcuser=$rpcuser\nrpcpassword=$rpcpassword\nserver=1\nlisten=1\ndaemon=1\nport=24055\nrpcallowip=127.0.0.1\nexternalip=$VPSIP:24055\nmasternode=1\nmasternodeprivkey=$MASTERNODEPRIVKEY" > ~/.swipp/swipp.conf

echo "Add Daemon Cronjob"
(crontab -l ; echo "@reboot /usr/local/bin/swippd")| crontab -

echo "Starting Swipp Daemon"
swippd

echo "Watch getinfo for block sync"
watch -n 10 'swippd getinfo'
