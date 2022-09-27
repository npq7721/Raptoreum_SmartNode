# Raptoreum SmartNode
Script needs to be ran under a sudo user and not under root. It will install binaries, configure basic firewall settings, and create a daemon service for you. It also has a bootstrap option for quick syncing and option to create a Cron job that will check on daemon's health every hour.  

> ℹ Note: This has only been tested on a VPS using Ubuntu 20. USE AT OWN RISK.

## Installation without Docker
Create a sudo user and run this under that sudo user. Script will exit if logged in as root.  
Script will ask for BLS PrivKey(operatorSecret) that you get from the protx quick_setup/bls generate command. So have it ready.  
If opting to have script create Cron job you will need the protx hash you got from the protx quick_setup.  
Please check [Wiki](https://github.com/dk808/Raptoreum_SmartNode/wiki) for a detailed guide.
```bash
bash <(curl -s https://raw.githubusercontent.com/dk808/Raptoreum_Smartnode/main/install.sh)
```
> ℹ Info: This will also create a script to update binaries.
***
## Installation using Docker
Install docker if you don't have it installed on the server. Execute everything below as one command while logged in as root.
```bash
sudo apt-get update && sudo apt-get install docker docker-compose
```
If planning to run container under user add user to docker group. Replace USER with username you will run container with.
```bash
adduser USER docker
```
Create a directory to use for volume so you have persistent data for the container to use.
```bash
mkdir docker-rtm
```
Create docker-compose.yml from one of the sample below

### docker-compose.yml for normal node
```yaml
version: '3.2'

services:
  raptoreum:
    image: npq7721/raptoreum:1.13.17.01
    container_name: normal_raptoreum_node # name of the container, change it if u want different name
    ports:
      - "10226:10226" #map raptoreum core port for peer to peer communication
    volumes:
      - /root/docker-rtm/:/raptoreum #maping /root/docker-rtm from host machine to /raptoreum folder in docker container
    restart: unless-stopped
    environment:
      BOOTSTRAP: "https://bootstrap.raptoreum.com/bootstraps_for_v1.3.17.00/bootstrap.tar.xz" #normal bootstrap
      FORCE_BOOTSTRAP: "false" # change to true if u want to redownload bootstrap
      CONF: | #this is raptoreum.conf
        rpcuser=rpcuser
        rpcpassword=rpcpassword
        rpcallowip=127.0.0.1
        rpcbind=127.0.0.1
        server=1
        listen=1
        externalip=139.59.151.120
        addnode=209.151.150.72
        addnode=94.237.79.27
        addnode=95.111.216.12
        addnode=198.100.149.124
        addnode=198.100.146.111
        addnode=5.135.187.46
        addnode=5.135.179.95
        addnode=139.59.7.178
        addnode=167.172.60.177
```
### docker-compose.yml for smartnode
```yaml
version: '3.2'

services:
  raptoreum:
    image: npq7721/raptoreum:1.13.17.01
    container_name: smart_raptoreum_node # name of the container, change it if u want different name
    ports:
      - "10226:10226" # map raptoreum core port for peer to peer communication
    volumes:
      - /root/docker-rtm/:/raptoreum #maping /root/docker-rtm from host machine to /raptoreum folder in docker container
    restart: unless-stopped
    environment:
      BOOTSTRAP: "https://bootstrap.raptoreum.com/bootstraps_for_v1.3.17.00/bootstrap.tar.xz" #normal bootstrap
      FORCE_BOOTSTRAP: "false" # change to true if u want to redownload bootstrap
      PROTX_HASH: #ur smartnode protx hash
      CONF: | #this is raptoreum.conf
        rpcuser=rpcuser
        rpcpassword=rpcpassword
        rpcallowip=127.0.0.1
        rpcbind=127.0.0.1
        server=1
        listen=1
        par=2
        dbcache=1024
        maxconnections=125
        smartnodeblsprivkey=put_ur_private_bls_key_here
        externalip=your_vps_public_ip
        addnode=209.151.150.72
        addnode=94.237.79.27
        addnode=95.111.216.12
        addnode=198.100.149.124
        addnode=198.100.146.111
        addnode=5.135.187.46
        addnode=5.135.179.95
        addnode=139.59.7.178
        addnode=167.172.60.177
```
### docker-compose.yml for index node
```yaml
version: '3.2'

services:
  raptoreum:
    image: npq7721/raptoreum:1.13.17.01
    container_name: index_raptoreum_node # name of the container, change it if u want different name
    ports:
      - "10226:10226" #map raptoreum core port for peer to peer communication
      - "10420:10420" # this is the same port as rpcport to allow rpc call.
    volumes:
      - /root/docker-rtm/:/raptoreum #maping /root/docker-rtm from host machine to /raptoreum folder in docker container
    restart: unless-stopped
    environment:
      BOOTSTRAP: "https://bootstrap.raptoreum.com/bootstraps_for_v1.3.17.00/bootstrap-index.tar.xz" #index bootstrap
      FORCE_BOOTSTRAP: "false" # change to true if u want to redownload bootstrap
      CONF: | #this is raptoreum.conf
        rpcuser=rpcuser
        rpcpassword=rpcpassword
        rpcallowip=127.0.0.1
        rpcbind=127.0.0.1
        rpcport=10420
        server=1
        listen=1
        txindex=1
        addressindex=1
        futureindex=1
        spentindex=1
        timestampindex=1
        externalip=139.59.151.120
        addnode=209.151.150.72
        addnode=94.237.79.27
        addnode=95.111.216.12
        addnode=198.100.149.124
        addnode=198.100.146.111
        addnode=5.135.187.46
        addnode=5.135.179.95
        addnode=139.59.7.178
        addnode=167.172.60.177
```
__Do not forget to open port 10226__  
> ℹ Info: You could ask support questions in [Raptoreum's Discord](https://discord.gg/wqgcxT3Mgh)