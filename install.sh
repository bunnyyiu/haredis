#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

apt-get update

apt-get install curl -y
apt-get install automake -y
apt-get install libtool -y
apt-get install git -y
apt-get install psmisc -y
apt-get install iwatch -y

apt-get install redis-server -y
systemctl stop redis-server
systemctl disable redis-server

apt-get install nodejs -y
apt-get install nodejs-legacy -y
apt-get install npm -y

pushd .
git clone https://github.com/twitter/twemproxy.git
cd twemproxy
autoreconf -fvi
./configure
make
make install
popd
rm -rf twemproxy

cp redisConfigs/* /etc/redis/
cp twemproxy.cfg /etc/twemproxy.cfg

cp -r sentinelTwemproxy /opt/
pushd .
cd /opt/sentinelTwemproxy
npm install
popd

# remove old data, for testing
rm -f /var/lib/redis/*.rdb
rm -f /var/lib/redis/*.aof

mkdir -p /var/run/redis
