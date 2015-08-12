#!/bin/bash

apt-get update

apt-get install curl
apt-get install automake
apt-get install libtool
apt-get install git

apt-get install redis-cli
systemctl stop redis-server
systemctl disable redis-server

apt-get install haproxy
systemctl stop haproxy
systemctl disable haproxy

apt-get install nodejs
apt-get install npm
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
