# OpenVPN
## Pre-requisites
- EJBCA Server
- Ubuntu Server for OpenVPN
- Token which supports PKCS#11
## Install OpenVPN Server on Ubuntu
Follow step by step in openvpn_install.sh with sample config.
## Install OpenVPN Client
### On Windows
- Download OpenVPN GUI application for Windows
- Copy file .ovpn from Server to C:\Program Files\OpenVPN\config and connect
### On Ubuntu
#### Install OpenVPN
sudo apt update
sudo apt install openvpn
#### Config file .ovpn for Ubuntu
Follow sample config
#### Connect to OpenVPN Server
sudo openvpn --config client.ovpn
