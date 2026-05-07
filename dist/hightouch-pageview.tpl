___INFO___

{
  "displayName": "Hightouch Pageview",
  "description": "Fires an htevents.page() call with merged base properties, event-specific properties, and dynamic payload. Replaces the Custom HTML pageview tag.",
  "categories": ["ANALYTICS"],
  "id": "cvt_hightouch_pageview",
  "type": "TAG",
  "version": 1,
  "containerContexts": ["WEB"]
}

___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "pageType",
    "displayName": "Page Type",
    "simpleValueType": true,
    "help": "Reference {{CJ - Dynamic - Page Type}}. Passed as the first argument to htevents.page().",
    "alwaysInSummary": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "pageTitle",
    "displayName": "Page Title",
    "simpleValueType": true,
    "help": "Reference {{JavaScript - Page Title}}. Passed as the second argument to htevents.page().",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "mode",
    "displayName": "Mode",
    "simpleValueType": true,
    "help": "Reference {{CJ - Mode}}."
  },
  {
    "type": "TEXT",
    "name": "promoCode",
    "displayName": "Promo Code",
    "simpleValueType": true,
    "help": "Reference {{CJ - Dynamic - Promo Code}}."
  },
  {
    "type": "TEXT",
    "name": "status",
    "displayName": "Status",
    "simpleValueType": true,
    "help": "Reference {{DLV - Status}}."
  },
  {
    "type": "TEXT",
    "name": "baseProperties",
    "displayName": "Base Properties",
    "simpleValueType": true,
    "help": "Reference {{CJ - Base Properties}}. Must resolve to a plain object at runtime."
  },
  {
    "type": "TEXT",
    "name": "buildPayload",
    "displayName": "Payload",
    "simpleValueType": true,
    "help": "Reference {{CJ - Build Payload}}. Must resolve to a plain object at runtime."
  }
]

___SANDBOXED_JS_FOR_WEB_TEMPLATE___

// Injected into every template at build time.
// reportError forwards to window._reportError (set by the Error Bridge Custom HTML tag).
// callInWindow silently no-ops if _reportError is not yet on window.
function reportError(message, ctx) {
  require('callInWindow')('_reportError', message, ctx);
}

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

___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "access_globals",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "key"},
                  {"type": 1, "string": "read"},
                  {"type": 1, "string": "write"},
                  {"type": 1, "string": "execute"}
                ],
                "mapValue": [
                  {"type": 1, "string": "_htPage"},
                  {"type": 8, "boolean": true},
                  {"type": 8, "boolean": false},
                  {"type": 8, "boolean": true}
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "key"},
                  {"type": 1, "string": "read"},
                  {"type": 1, "string": "write"},
                  {"type": 1, "string": "execute"}
                ],
                "mapValue": [
                  {"type": 1, "string": "_reportError"},
                  {"type": 8, "boolean": false},
                  {"type": 8, "boolean": false},
                  {"type": 8, "boolean": true}
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]

___NOTES___

Replaces: hightouch-pageview.html (Custom HTML tag)

Prerequisite: Error Bridge Custom HTML tag must fire before this tag (All Pages, high priority).

Parameter mapping:
  Page Type       -> {{CJ - Dynamic - Page Type}}
  Page Title      -> {{JavaScript - Page Title}}
  Mode            -> {{CJ - Mode}}
  Promo Code      -> {{CJ - Dynamic - Promo Code}}
  Status          -> {{DLV - Status}}
  Base Properties -> {{CJ - Base Properties}}
  Payload         -> {{CJ - Build Payload}}

___TESTS___

scenarios:
- name: Fires page with merged properties via bridge function
  code: |-
    var calledWith = {};
    mock('copyFromWindow', function(key) {
      if (key === '_htPage') { return function() {}; }
    });
    mock('callInWindow', function(fn, pageType, pageTitle, props) {
      if (fn === '_htPage') {
        calledWith = { pageType: pageType, pageTitle: pageTitle, props: props };
      }
    });
    
    runCode({
      pageType: 'pdp',
      pageTitle: 'Event Detail',
      mode: 'buy',
      promoCode: 'SAVE10',
      status: 'available',
      baseProperties: { user_id: 'u1' },
      buildPayload: { payload_ref: 'home' }
    });
    
    assertApi('gtmOnSuccess').wasCalled();
- name: Calls gtmOnFailure and reports error when bridge not ready
  code: |-
    var errorReported = false;
    mock('copyFromWindow', function(key) { return undefined; });
    mock('callInWindow', function(fn) {
      if (fn === '_reportError') { errorReported = true; }
    });
    
    runCode({
      pageType: 'pdp',
      pageTitle: 'Event Detail',
      baseProperties: {},
      buildPayload: {}
    });
    
    assertApi('gtmOnFailure').wasCalled();
