#!/bin/bash

for f in services/*
do
  cp $f /etc/init.d/
  name=${f##*/}
  update-rc.d $name defaults
  systemctl daemon-reload
  systemctl enable $name
  service $name start
done
