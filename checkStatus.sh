#!/bin/bash

sport=26379

# Returns the config (ip port) of group master redis
function getShardConfig {
  name=$1
  port=$2
  echo `redis-cli -p $port sentinel get-master-addr-by-name $name`
}

# Checks if the redis instance is running
function isRunning {
  port=$2
  val=`redis-cli -p $port ping 2>/dev/null`
  if [ "$val" = "PONG" ]; then
    echo "YES"
  else
    echo "NO"
  fi
}

# Check Redis status
function redisStatus {
  # check if those 1000 items are all exist
  ./checkData.sh > /dev/null
  if [ $? = 0 ]; then
    echo "Redis OK (1000 items all existed)"
  else
    echo "Redis NOT OK"
  fi
}

# Get Redis slaves
function getRedisSlaves {
  name=$1
  port=$2
  echo `redis-cli -p $port sentinel slaves $name`
}

# Check slaves status
function checkSlaves {
  slavesConfig=$1
  getIP=0
  getPort=0
  ip=""
  for i in $slavesConfig
  do
    if [ $getIP == 1 ]; then
      ip=$i
      getIP=0
      continue
    fi
    if [ $getPort == 1 ]; then
      isRun=$(isRunning $ip $i)
      printf "\t$ip $i : $isRun\n"
      getPort=0
      continue
    fi
    if [ "$i" = "ip" ]; then
      getIP=1
      continue
    fi
    if [ "$i" = "port" ]; then
      getPort=1
    fi
  done
}

# Check is Redis sentinel is running
sentinelIsRunning=$(isRunning "" $sport)
if [ "$sentinelIsRunning" = "NO" ]; then
  echo "Redis sentinel is not running. This script requires redis sentinel to work."
  exit 1
fi
printf "Redis sentinel running :\n\t127.0.0.1 $sport : $sentinelIsRunning\n"

# Check if main port ready
mainPort=6379
mainIsRunning=$(isRunning "127.0.0.1" $mainPort)
echo "$mainPort port running :"
printf "\t127.0.0.1 $mainPort : $mainIsRunning\n"

# Check if shard 1 ready
shard1Config=$(getShardConfig "redis-s1" $sport)
shard1MasterStatus=$(isRunning $shard1Config)
echo "Shard 1 master running :"
printf "\t$shard1Config : $shard1MasterStatus\n"

# Check shard 1 slave status
shard1Slaves=$(getRedisSlaves "redis-s1" $sport)
slave1=$(checkSlaves "$shard1Slaves")
echo "Shard 1 slaves running : "
echo "$slave1"

# Check if shard 2 ready
shard2Config=$(getShardConfig "redis-s2" $sport)
shard2MasterStatus=$(isRunning $shard2Config)
echo "Shard 2 master :"
printf "\t$shard2Config : $shard2MasterStatus\n"

# Check shard 2 slave status
shard2Slaves=$(getRedisSlaves "redis-s2" $sport)
slave2=$(checkSlaves "$shard2Slaves")
echo "Shard 2 slaves running : "
echo "$slave2"
