var callInWindow = require('callInWindow');
var copyFromWindow = require('copyFromWindow');
var logToConsole = require('logToConsole');

if (!copyFromWindow('_htTrack')) {
  logToConsole('[Hightouch Track] SDK bridge not ready (_htTrack not found). Has the init tag fired and completed SDK load?');
  reportError('[GTM:error] _htTrack not found on window', { template: 'hightouch-track', eventName: data.eventName });
  data.gtmOnFailure();
  return;
}

var eventProperties = {};
if (data.interaction !== undefined)     eventProperties.interaction = data.interaction;
if (data.sourcePageType !== undefined)  eventProperties.source_page_type = data.sourcePageType;
if (data.targetPageType !== undefined)  eventProperties.target_page_type = data.targetPageType;
if (data.searchSessionId !== undefined) eventProperties.search_session_id = data.searchSessionId;
if (data.searchTerm !== undefined)      eventProperties.search_term = data.searchTerm;

var properties = {};
var sources = [data.baseProperties || {}, eventProperties, data.buildPayload || {}];
for (var i = 0; i < sources.length; i++) {
  var src = sources[i];
  for (var key in src) {
    properties[key] = src[key];
  }
}

logToConsole('[Hightouch Track]', data.eventName, properties);
callInWindow('_htTrack', data.eventName, properties);
data.gtmOnSuccess();
