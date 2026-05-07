var callInWindow = require('callInWindow');
var copyFromWindow = require('copyFromWindow');
var logToConsole = require('logToConsole');

if (!copyFromWindow('_htPage')) {
  logToConsole('[Hightouch Pageview] SDK bridge not ready (_htPage not found). Has the init tag fired and completed SDK load?');
  reportError('[GTM:error] _htPage not found on window', { template: 'hightouch-pageview', pageType: data.pageType });
  data.gtmOnFailure();
  return;
}

var eventProperties = {};
if (data.mode !== undefined)      eventProperties.mode = data.mode;
if (data.promoCode !== undefined) eventProperties.promo_code = data.promoCode;
if (data.status !== undefined)    eventProperties.status = data.status;

var properties = {};
var sources = [data.baseProperties || {}, eventProperties, data.buildPayload || {}];
for (var i = 0; i < sources.length; i++) {
  var src = sources[i];
  for (var key in src) {
    properties[key] = src[key];
  }
}

logToConsole('[Hightouch Pageview]', data.pageType, data.pageTitle, properties);
callInWindow('_htPage', data.pageType, data.pageTitle, properties);
data.gtmOnSuccess();
