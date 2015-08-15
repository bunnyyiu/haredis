#!/bin/bash

sport=26379


function setUp {
  echo "Kill all related processes"
  ./killall.sh &> /dev/null
  sleep 1
  echo "Reload configs"
  ./reloadConfig.sh &> /dev/null

  echo "Remove old data"
  rm /var/lib/redis/*.rdb
  rm /var/lib/redis/*.aof

  echo "Start the stack"
  ./run.sh &> /dev/null
  ./loadData.sh
}

function tearDown {
  ./killall.sh > /dev/null
}
# ensure tearDown is called even this script break
trap tearDown EXIT

# Returns the config (ip port) of group master redis
function getShardConfig {
  name=$1
  echo `redis-cli -p $sport sentinel get-master-addr-by-name $name`
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

# Kill Redis by config
function killRedisByConfig {
  port=$2
  pid=`ps auxww | grep redis-server | grep "$port" | awk '{print $2}'`
  kill -9 $pid
  pidFileToRemove=`grep $pid /var/run/redis/redis_* -l`
  rm $pidFileToRemove
}

# Polls until the shard is ready
function waitForShardReady {
  name=$1
  timeout=$2

  running=""
  slept=0
  while [ "$running" != "YES" ] && [ "$slept" -lt "$timeout" ]; do
    config=$(getShardConfig $name)
    running=$(isRunning $config)
    sleep 1
    ((slept++))
    printf .
  done
  sleep 1
  echo .
}

function redisStatus {
  # check if those 1000 items are all exist
  ./checkData.sh > /dev/null
  if [ $? = 0 ]; then
    echo "Redis OK (1000 items all existed)"
  else
    echo "Redis NOT OK"
  fi
}

function startShutedDownRedis {
   for f in /etc/redis/redis_s*.conf; do
     # get the file name without path and extensions
     name=${f##*/}
     name=${name%.conf}
     if [ ! -f /var/run/redis/$name.pid ]; then
       redis-server $f
     fi
   done
}

function testcase1 {
  name="redis-s1"
  config=$(getShardConfig $name)
  printf "Test case 1 : kill the master node of shard 1 ($config): "
  killRedisByConfig $config

  # poll for 5 seconds
  waitForShardReady $name 5

  newConfig=$(getShardConfig $name)
  echo "New master is $newConfig"

  echo `redisStatus`
  echo
}

function testcase2 {
  name="redis-s2"
  config=$(getShardConfig $name)
  printf "Test case 2 : kill the master node of shard 2 ($config): "
  killRedisByConfig $config

  # poll for 5 seconds
  waitForShardReady $name 5

  newConfig=$(getShardConfig $name)
  echo "New master is $newConfig"

  echo `redisStatus`
  echo
}

function testcase3 {
  name1="redis-s1"
  config1=$(getShardConfig $name1)

  name2="redis-s2"
  config2=$(getShardConfig $name2)

  echo "Test case 3 : kill the master nodes of shard 1 & 2 ($config1, $config2): "
  killRedisByConfig $config1
  killRedisByConfig $config2

  # poll for 5 seconds
  waitForShardReady $name1 5 &> /dev/null &
  waitForShardReady $name2 5 &> /dev/null &
  wait

  newConfig1=$(getShardConfig $name1)
  newConfig2=$(getShardConfig $name2)
  echo "New master of shard 1 is $newConfig1"
  echo "New master of shard 2 is $newConfig2"

  echo `redisStatus`
  echo
}

function getRedisSlaves {
  name=$1
  echo `redis-cli -p $sport sentinel slaves $name`
}

function testcase4 {
  sleep 5
  name1="redis-s1"
  config1=$(getShardConfig $name1)

  name2="redis-s2"
  config2=$(getShardConfig $name2)

  shard1Slaves=$(getRedisSlaves $name1 | awk '{print $4 " " $6}')
  shard2Slaves=$(getRedisSlaves $name2 | awk '{print $4 " " $6}')

  echo "Test case 4 : kill flour redis instances (two instances [one master, one slave] in each shard) ($config1, $shard1Slaves, $config2, $shard2Slaves):"

  killRedisByConfig $shard1Slaves
  killRedisByConfig $config1
  killRedisByConfig $shard2Slaves
  killRedisByConfig $config2

  # poll for 10 seconds
  waitForShardReady $name1 10 &> /dev/null &
  waitForShardReady $name2 10 &> /dev/null &
  wait

  newConfig1=$(getShardConfig $name1)
  newConfig2=$(getShardConfig $name2)
  echo "New master of shard 1 is $newConfig1"
  echo "New master of shard 2 is $newConfig2"

  echo `redisStatus`
  echo
}

setUp

testcase1
startShutedDownRedis

testcase2
startShutedDownRedis

testcase3
startShutedDownRedis

testcase4
#startShutedDownRedis
