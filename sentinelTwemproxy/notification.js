#!/usr/bin/env node
"use strict";

var yaml = require('js-yaml');
var fs = require('fs');
var exec = require('child_process').exec;

var TWEMPROXY_PATH = '/etc/twemproxy.cfg';
var SWITCH_MASTER = '+switch-master';
var MONITOR = '+monitor';
var SHARD_INDEX = /[0-9]+$/;
var MASTER = 'master';
var LOG_PATH = '/var/run/nutcracker/twemproxy_notification.log';
var PID_FILE = '/var/run/nutcracker/sentinel_twemproxy.pid';
var WATCH_FILE = '/var/lib/redis/nutcracker_update';
var WATCH_PID = '/var/run/nutcracker/nutcracker.WATCH.pid'

var log = function (content, callback) {
  if (!callback) {
    callback = function () {};
  }
  fs.appendFile(LOG_PATH, content + "\n", callback);
};

process.on('uncaughtException', function (err) {
  log("uncaughtException : " + err, function () {
    process.exit(0);
  });
});

var lock = function (path, callback) {
  fs.stat(path, function (err) {
    // file exist
    if (!err) {
      setTimeout(function () {
        lock(path, callback);
      }, 50);
      return;
    }
    fs.appendFile(path, process.pid, function () {
      process.on('exit', function () {
        fs.unlinkSync(path);
      });
      process.nextTick(callback);
    });
  });
};

var yamlToJson = function (path) {
  var doc = null;
  try {
    var content = fs.readFileSync(path, 'utf8');
    doc = yaml.safeLoad(content);
  } catch (e) {
    log("failed to parse " + TWEMPROXY_PATH);
  }
  return doc;
};

var isSwitchMasterEvent = function (type) {
  return type === SWITCH_MASTER;
};

var isMonitorEvent = function (type, subtype) {
  return type === MONITOR && subtype === MASTER;
};

var getShardIndex = function (shardName) {
  return parseInt(SHARD_INDEX.exec(shardName)[0], 10) - 1;
};

var updateConfig = function (configs, shardName, oldIp, oldPort, ip, port) {
  var groupName = shardName.split("-")[0];
  var shardIndex = getShardIndex(shardName);
  var config = configs[groupName];

  if (!config || !config.servers) {
    return configs;
  }

  var newConfig = JSON.parse(JSON.stringify(configs));
  var currentShardConfig = config.servers[shardIndex].split(':');
  if ((currentShardConfig[0] !== oldIp || currentShardConfig[1] !== oldPort) &&
      (oldIp != null && oldPort != null)) {
    return configs;
  }
  currentShardConfig[0] = ip;
  currentShardConfig[1] = port;
  newConfig[groupName].servers[shardIndex] = currentShardConfig.join(':');
  return newConfig;
};

var writeConfig = function (config, path) {
  var content = yaml.safeDump(config);
  fs.writeFileSync(path, content);
};

var restartTwemproxy = function () {
  var commands = [
    'killall nutcracker',
    '/usr/local/sbin/nutcracker -d -c ' + TWEMPROXY_PATH
  ];
  exec(commands.join(';'));
};

var processSwitchMasterMessage = function () {
  var shardName = args[0];
  var oldIp = args[1];
  var oldPort = args[2];
  var ip = args[3];
  var port = args[4];

  var currentConfig = yamlToJson(TWEMPROXY_PATH);
  if (!currentConfig) {
    return;
  }
  var newConfig = updateConfig(currentConfig, shardName, oldIp, oldPort,
                               ip, port);
  if (JSON.stringify(currentConfig) === JSON.stringify(newConfig)) {
    return;
  }
  var pathToWrite = WATCH_FILE;
  var writeToWatchFile = true;
  try {
    fs.statSync(WATCH_PID);
  } catch (e) {	
    writeToWatchFile = false;
  }
  var pathToWrite = writeToWatchFile ? WATCH_FILE : TWEMPROXY_PATH;
  writeConfig(newConfig, pathToWrite);
  if (!writeToWatchFile) {
    restartTwemproxy();
  }
};

var processMonitorMessage = function () {
  var shardName = args[1];
  var ip = args[2]
  var port = args[3];

  var currentConfig = yamlToJson(TWEMPROXY_PATH);
  if (!currentConfig) {
    return;
  }
  var newConfig = updateConfig(currentConfig, shardName, null, null,
                               ip, port);
  if (JSON.stringify(currentConfig) === JSON.stringify(newConfig)) {
    return;
  }
  var pathToWrite = WATCH_FILE;
  var writeToWatchFile = true;
  try {
    fs.statSync(WATCH_PID);
  } catch (e) {	
    writeToWatchFile = false;
  }
  var pathToWrite = writeToWatchFile ? WATCH_FILE : TWEMPROXY_PATH;
  writeConfig(newConfig, pathToWrite);
  if (!writeToWatchFile) {
    restartTwemproxy();
  }
};

log(process.argv);
var type = process.argv[2];
var args = process.argv[3].split(" ");
if (isSwitchMasterEvent(type)) {
  lock(PID_FILE, processSwitchMasterMessage);
} else if (isMonitorEvent(type, args[0])) {
  lock(PID_FILE, processMonitorMessage);
}
