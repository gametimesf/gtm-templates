var callInWindow = require('callInWindow');
var copyFromWindow = require('copyFromWindow');
var logToConsole = require('logToConsole');

if (!copyFromWindow('DD_RUM')) {
  logToConsole('[Datadog RUM] DD_RUM not found on window');
  reportError('[GTM:error] DD_RUM not found on window', { template: 'datadog-rum', method: data.method, actionName: data.actionName });
  data.gtmOnFailure();
  return;
}

var context = {};
var rows = data.context || [];
for (var i = 0; i < rows.length; i++) {
  if (rows[i].key) {
    context[rows[i].key] = rows[i].value;
  }
}

var payload = data.buildPayload || {};
for (var key in payload) {
  context[key] = payload[key];
}

logToConsole('[Datadog RUM]', data.method, data.actionName, context);

if (data.method === 'setUser') {
  callInWindow('DD_RUM.setUser', context);
} else if (data.method === 'setAccount') {
  callInWindow('DD_RUM.setAccount', context);
} else {
  callInWindow('DD_RUM.addAction', data.actionName, context);
}

data.gtmOnSuccess();
