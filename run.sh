#!/bin/bash

# shard 1 master
redis-server /etc/redis/redis_s1_1.conf

# shard 2 master
redis-server /etc/redis/redis_s2_1.conf

sleep 2

# sentinel
redis-server /etc/redis/sentinel.conf --sentinel

sleep 2
redis-server /etc/redis/redis_s1_2.conf
sleep 2
redis-server /etc/redis/redis_s1_3.conf
sleep 2
redis-server /etc/redis/redis_s2_2.conf
sleep 2
redis-server /etc/redis/redis_s2_3.conf

# haproxy
/usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg

# twemproxy
/usr/local/sbin/nutcracker -c /etc/twemproxy.cfg -d

sleep 2
