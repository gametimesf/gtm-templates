___INFO___

{
  "displayName": "Hightouch Init",
  "description": "Initializes the Hightouch htevents stub and loads the Hightouch SDK. Use once per page, firing on all pages. Replaces the Custom HTML init tag to avoid DOM bloat in SPAs.",
  "categories": ["ANALYTICS"],
  "id": "cvt_hightouch_init",
  "type": "TAG",
  "version": 1,
  "containerContexts": ["WEB"]
}

___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "environment",
    "displayName": "Environment",
    "simpleValueType": true,
    "help": "Reference {{ENV}}. When the value equals 'production', the production API key is used; otherwise the dev/staging key is used.",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "prodApiKey",
    "displayName": "Production API Key",
    "simpleValueType": true,
    "help": "Reference {{Hightouch - API Key [PROD]}}. Used when Environment equals 'production'.",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "devApiKey",
    "displayName": "Dev / Staging API Key",
    "simpleValueType": true,
    "help": "Reference {{Hightouch - API Key}}. Used when Environment is not 'production'.",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "apiHost",
    "displayName": "API Host",
    "simpleValueType": true,
    "help": "Reference {{Hightouch - API Host}}. Passed as { apiHost } in the SDK load options.",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  }
]

___SANDBOXED_JS_FOR_WEB_TEMPLATE___

var copyFromWindow = require('copyFromWindow');
var setInWindow = require('setInWindow');
var injectScript = require('injectScript');
var logToConsole = require('logToConsole');

// Guard against double-init
var existing = copyFromWindow('htevents');
if (existing && existing.invoked) {
  logToConsole.error('Hightouch snippet included twice.');
  data.gtmOnSuccess();
  return;
}

// Set up the htevents queuing stub (mirrors the original minified snippet)
setInWindow('htevents', existing || [], false);
var e = copyFromWindow('htevents');

e.invoked = true;
e.methods = [
  'trackSubmit', 'trackClick', 'trackLink', 'trackForm', 'pageview',
  'identify', 'reset', 'group', 'track', 'ready', 'alias', 'debug',
  'page', 'once', 'off', 'on', 'addSourceMiddleware',
  'addIntegrationMiddleware', 'setAnonymousId', 'addDestinationMiddleware'
];

// Factory: each stub method queues calls until the real SDK loads and replaces them
e.factory = function(methodName) {
  return function() {
    var args = [];
    for (var i = 0; i < arguments.length; i++) { args.push(arguments[i]); }
    args.unshift(methodName);
    e.push(args);
    return e;
  };
};

for (var i = 0; i < e.methods.length; i++) {
  e[e.methods[i]] = e.factory(e.methods[i]);
}

e.SNIPPET_VERSION = '0.0.1';
e._writeKey = data.environment === 'production' ? data.prodApiKey : data.devApiKey;
e._loadOptions = { apiHost: data.apiHost };

// Load SDK via injectScript — cacheKey prevents duplicate loads on SPA navigations
var sdkUrl = 'https://cdn.hightouch-events.com/browser/release/v1-latest/events.min.js';
injectScript(sdkUrl, function() {
  e.page();
  data.gtmOnSuccess();
}, data.gtmOnFailure, sdkUrl);

___NOTES___

Replaces: hightouch-init.html (Custom HTML tag)

Why use this template instead of Custom HTML:
- The stub setup code no longer creates a persistent <script> element in the DOM
- injectScript uses a cacheKey so the SDK is only fetched once, even if this
  tag fires on multiple SPA route changes

Parameter mapping:
  Environment     -> {{ENV}}
  Prod API Key    -> {{Hightouch - API Key [PROD]}}
  Dev API Key     -> {{Hightouch - API Key}}
  API Host        -> {{Hightouch - API Host}}

This tag should fire on All Pages / DOM Ready or Window Loaded, before any
other Hightouch tags.

___TESTS___

[
  {
    "name": "Initializes stub and loads SDK when htevents is absent",
    "code": "var hteventsStub;\nmock('copyFromWindow', function(key) {\n  if (key === 'htevents') return hteventsStub;\n  return undefined;\n});\nmock('setInWindow', function(key, value) {\n  if (key === 'htevents') hteventsStub = value;\n});\nmock('injectScript', function(url, onSuccess, onFailure, cacheKey) {\n  onSuccess();\n});\nmock('logToConsole', { error: function() {}, log: function() {} });\n\nrunCode({\n  environment: 'staging',\n  prodApiKey: 'prod-key',\n  devApiKey: 'dev-key',\n  apiHost: 'us-east-1.hightouch-events.com'\n});\n\nassertApi('gtmOnSuccess').wasCalled();"
  },
  {
    "name": "Logs error and succeeds gracefully when snippet fires twice",
    "code": "var alreadyInit = { invoked: true };\nmock('copyFromWindow', function(key) {\n  if (key === 'htevents') return alreadyInit;\n  return undefined;\n});\nmock('setInWindow', function() {});\nmock('injectScript', function() {});\nmock('logToConsole', { error: function() {}, log: function() {} });\n\nrunCode({\n  environment: 'production',\n  prodApiKey: 'prod-key',\n  devApiKey: 'dev-key',\n  apiHost: 'us-east-1.hightouch-events.com'\n});\n\nassertApi('gtmOnSuccess').wasCalled();"
  },
  {
    "name": "Calls gtmOnFailure when SDK load fails",
    "code": "var hteventsStub;\nmock('copyFromWindow', function(key) {\n  if (key === 'htevents') return hteventsStub;\n  return undefined;\n});\nmock('setInWindow', function(key, value) {\n  if (key === 'htevents') hteventsStub = value;\n});\nmock('injectScript', function(url, onSuccess, onFailure, cacheKey) {\n  onFailure();\n});\nmock('logToConsole', { error: function() {}, log: function() {} });\n\nrunCode({\n  environment: 'production',\n  prodApiKey: 'prod-key',\n  devApiKey: 'dev-key',\n  apiHost: 'us-east-1.hightouch-events.com'\n});\n\nassertApi('gtmOnFailure').wasCalled();"
  }
]
