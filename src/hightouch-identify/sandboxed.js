var callInWindow = require('callInWindow');
var copyFromWindow = require('copyFromWindow');
var logToConsole = require('logToConsole');

if (!copyFromWindow('_htIdentify')) {
  logToConsole('[Hightouch Identify] SDK bridge not ready (_htIdentify not found). Has the init tag fired and completed SDK load?');
  reportError('[GTM:error] _htIdentify not found on window', { template: 'hightouch-identify' });
  data.gtmOnFailure();
  return;
}

callInWindow('_htSetAnonId', data.deviceId);

var userId = data.userId;
var traits = {
  email: data.email,
  phone: data.phone,
  deviceId: data.deviceId,
  sessionId: data.sessionId,
  mongoId: data.userId
};

logToConsole('[Hightouch Identify]', userId, traits);
callInWindow('_htIdentify', userId, traits);
data.gtmOnSuccess();
