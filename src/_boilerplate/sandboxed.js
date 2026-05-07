var callInWindow = require('callInWindow');
var copyFromWindow = require('copyFromWindow');
var logToConsole = require('logToConsole');

// Guard: check that the required window global exists before calling it.
// Replace 'myGlobal' with the bridge function or SDK global this template depends on.
if (!copyFromWindow('myGlobal')) {
  logToConsole('[My Template] myGlobal not found on window');
  reportError('[GTM:error] myGlobal not found on window', { template: 'my-template-name' });
  data.gtmOnFailure();
  return;
}

// Template logic goes here.
// Use data.<paramName> to access parameter values.
logToConsole('[My Template]', data.myParam);
callInWindow('myGlobal', data.myParam);
data.gtmOnSuccess();
