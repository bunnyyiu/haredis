#!/bin/bash

apt-get update

apt-get install curl -y
apt-get install automake -y
apt-get install libtool -y
apt-get install git -y

apt-get install redis-cli -y
systemctl stop redis-server
systemctl disable redis-server

apt-get install haproxy -y
systemctl stop haproxy
systemctl disable haproxy

apt-get install nodejs -y
apt-get install npm -y
npm install haproxy -g

pushd .
git clone https://github.com/twitter/twemproxy.git
cd twemproxy
autoreconf -fvi
./configure
make
make install
popd
rm -rf twemproxy
