#!/bin/bash

cp redisConfigs/* /etc/redis/
cp haproxy.cfg /etc/haproxy/haproxy.cfg
cp twemproxy.cfg /etc/twemproxy.cfg

cp notification.sh /usr/local/sbin
