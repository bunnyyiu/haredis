#!/bin/bash

chown -R redis:redis /var/run/redis
chown -R redis:redis /var/log/redis
chown -R redis:redis /var/lib/redis
chown -R redis:redis /etc/redis

chown redis:redis /etc/twemproxy.cfg

for f in services/*
do
  cp $f /etc/init.d/
  name=${f##*/}
  update-rc.d $name defaults
  systemctl daemon-reload
  systemctl enable $name
  service $name start
done
