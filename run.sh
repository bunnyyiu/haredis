#!/bin/bash

# twemproxy
/usr/local/sbin/nutcracker -c /etc/twemproxy.cfg -d

# shard 1
redis-server /etc/redis/redis_s1_1.conf
redis-server /etc/redis/redis_s1_2.conf
redis-server /etc/redis/redis_s1_3.conf

# shard 2
redis-server /etc/redis/redis_s2_1.conf
redis-server /etc/redis/redis_s2_2.conf
redis-server /etc/redis/redis_s2_3.conf
sleep 1

# sentinel
redis-sentinel /etc/redis/sentinel.conf --sentinel
sleep 1
