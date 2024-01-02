#!/bin/bash
#
# https://github.com/HUSTOumaShu/OpenVPN_config
#
# Author: HustShu

# 1. Installing OpenVPN and Easy-RSA
sudo apt update
sudo apt install openvpn easy-rsa

mkdir ~/easy-rsa
ln -s /usr/share/easy-rsa/* ~/easy-rsa/
sudo chown -R root:root ~/easy-rsa
chmod 700 ~/easy-rsa

# 2. Creating a PKI for OpenVPN
cd ~/easy-rsa
touch vars
{
echo "set_var EASYRSA_ALGO \"ec\""
echo "set_var EASYRSA_DIGEST \"sha512\""
} > ~/easy-rsa/vars

cd ~/easy-rsa
./easyrsa init-pki

# 3. Creating an OpenVPN Server Certificate Request and Private Key

cd ~/easy-rsa
./easyrsa gen-req server nopass
## Keypair and CSR completed 
## req: ~/easy-rsa/pki/reqs/server.req
## key: ~/easy-rsa/pki/private/server.key

sudo cp ~/easy-rsa/pki/private/server.key /etc/openvpn/server/
## Signing file server.req with EJBCA Server and get file server.pem and ca.pem (certificate of Server and CA)
## and store at /tmp
sudo cp /tmp/{server.pem,ca.pem} /etc/openvpn/server

# 4. Configuring OpenVPN Cryptographic Material
## Generate tls-crypt shared key
cd ~/easy-rsa
openvpn --genkey --secret ta.key
sudo cp ta.key /etc/openvpn/server

# 5. Generating Client Certificate and Key Pair config
mkdir -p ~/client-configs/keys
chmod -R 700 ~/client-configs

## Generate key pair and certificate for client
cd ~/easy-rsa
./easyrsa gen-req client1 nopass
cp pki/private/client1.key ~/client-configs/keys/

## Send file pki/reqs/client1.req to EJBCA Server to get file client1.pem stored at /tmp
cp /tmp/client1.crt ~/client-configs/keys/
cp ~/easy-rsa/ta.key ~/client-configs/keys/
sudo cp /etc/openvpn/server/ca.crt ~/client-configs/keys/
sudo chown -R root:root ~/client-configs/keys/*

# 6. Configuring OpenVPN 
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/server/
gunzip /etc/openvpn/server server.conf.gz
sudo nano /etc/openvpn/server/server.conf

## Configuring server.conf follow OpenVPN References or sample file

# 7. Adjusting the OpenVPN Server Networking Configuration
sudo echo "net.ipv4.ip_forward = 1" > /etc/sysctl.conf
sudo sysctl -p

# 8. Firewall Configuration
{
echo "# START OPENVPN RULES"
echo "# NAT table rules"
echo "*nat"
echo ":POSTROUTING ACCEPT [0:0]"
echo "# Allow traffic from OpenVPN client to enp0s3 (change to the interface you discovered!)"
echo "-A POSTROUTING -s 10.8.0.0/8 -o enp0s3 -j MASQUERADE"
echo "COMMIT"
echo "# END OPENVPN RULES"
} > /etc/ufw/before.rules


echo "DEFAULT_FORWARD_POLICY=\"ACCEPT\"" > /etc/default/ufw
sudo ufw allow 1194/udp
sudo ufw allow OpenSSH

## Restart firewall
sudo ufw disable
sudo ufw enable

# 9. Creating Basic Client Configuration Infrastructure
mkdir -p ~/client-configs/files
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/client-configs/base.conf
touch ~/client-configs/make_config.sh
## Config base.conf follow OpenVPN 2.6 Reference or sample config on Github before next step
chmod 700 ~/client-configs/make_config.sh


# 10. Starting OpenVPN Server
sudo systemctl -f enable openvpn-server@server.service
sudo systemctl start openvpn-server@server.service
sudo systemctl status openvpn-server@server.service

# 11. Generating Client Configuration
cd ~/client-configs
./make_config.sh client1
ls ~/client-configs/files
## Send file client1.ovpn to client

# 12. Generating Client Configuration for Client using PKCS#11
cd ~/client-configs
touch pkcs11.conf
touch make_config_pkcs11.sh
## Config 2 files follow sample config on Github

# 13. Send ovpn file to client