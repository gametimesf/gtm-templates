var callInWindow = require('callInWindow');
var copyFromWindow = require('copyFromWindow');
var logToConsole = require('logToConsole');

var rootKey = data.windowFunction.split('.')[0];
if (!copyFromWindow(rootKey)) {
  logToConsole('[Generic JS Tag] "' + rootKey + '" not found on window');
  reportError('[GTM:error] "' + rootKey + '" not found on window', { template: 'generic-js-tag', windowFunction: data.windowFunction, eventName: data.eventName });
  data.gtmOnFailure();
  return;
}

var properties = {};
var rows = data.properties || [];
for (var i = 0; i < rows.length; i++) {
  if (rows[i].key) {
    properties[rows[i].key] = rows[i].value;
  }
}

var payload = data.buildPayload || {};
for (var key in payload) {
  properties[key] = payload[key];
}

logToConsole('[Generic JS Tag]', data.windowFunction, data.methodArg, data.eventName, properties);

if (data.methodArg) {
  callInWindow(data.windowFunction, data.methodArg, data.eventName, properties);
} else {
  callInWindow(data.windowFunction, data.eventName, properties);
}

data.gtmOnSuccess();
