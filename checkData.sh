#!/bin/bash

for i in {1..1000}
do
  val=`redis-cli get $i`
  if [ "$val" != "$i" ]
  then
     echo "Key $i:$val not match"
     exit 1
  fi
done
exit 0
