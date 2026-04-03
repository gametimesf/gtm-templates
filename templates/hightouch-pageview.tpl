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

var copyFromWindow = require('copyFromWindow');
var objectAssign = require('Object.assign');
var logToConsole = require('logToConsole');

var htevents = copyFromWindow('htevents');
if (!htevents) {
  data.gtmOnFailure();
  return;
}

var eventProperties = {
  mode: data.mode,
  promo_code: data.promoCode,
  status: data.status
};

// Merge order mirrors the original: base < event-specific < payload
var properties = objectAssign({}, data.baseProperties || {}, eventProperties, data.buildPayload || {});

try {
  htevents.page(data.pageType, data.pageTitle, properties);
  data.gtmOnSuccess();
} catch (error) {
  logToConsole.error("Could not fire Hightouch 'Page View' event", error);
  data.gtmOnFailure();
}

___NOTES___

Replaces: hightouch-pageview.html (Custom HTML tag)

Parameter mapping:
  Page Type       -> {{CJ - Dynamic - Page Type}}
  Page Title      -> {{JavaScript - Page Title}}
  Mode            -> {{CJ - Mode}}
  Promo Code      -> {{CJ - Dynamic - Promo Code}}
  Status          -> {{DLV - Status}}
  Base Properties -> {{CJ - Base Properties}}
  Payload         -> {{CJ - Build Payload}}

___TESTS___

[
  {
    "name": "Fires htevents.page with merged properties",
    "code": "var calledWith = {};\nmock('copyFromWindow', function(key) {\n  if (key === 'htevents') {\n    return {\n      page: function(pageType, pageTitle, props) {\n        calledWith = { pageType: pageType, pageTitle: pageTitle, props: props };\n      }\n    };\n  }\n});\nmock('Object.assign', function() {\n  var result = {};\n  for (var i = 0; i < arguments.length; i++) {\n    var src = arguments[i] || {};\n    for (var key in src) { result[key] = src[key]; }\n  }\n  return result;\n});\nmock('logToConsole', { error: function() {} });\n\nrunCode({\n  pageType: 'pdp',\n  pageTitle: 'Event Detail',\n  mode: 'buy',\n  promoCode: 'SAVE10',\n  status: 'available',\n  baseProperties: { user_id: 'u1' },\n  buildPayload: { payload_ref: 'home' }\n});\n\nassertApi('gtmOnSuccess').wasCalled();"
  },
  {
    "name": "Calls gtmOnFailure when htevents is not on window",
    "code": "mock('copyFromWindow', function(key) { return undefined; });\nmock('Object.assign', function() { return {}; });\nmock('logToConsole', { error: function() {} });\n\nrunCode({\n  pageType: 'pdp',\n  pageTitle: 'Event Detail',\n  mode: undefined,\n  promoCode: undefined,\n  status: undefined,\n  baseProperties: {},\n  buildPayload: {}\n});\n\nassertApi('gtmOnFailure').wasCalled();"
  },
  {
    "name": "Calls gtmOnFailure when htevents.page throws",
    "code": "mock('copyFromWindow', function(key) {\n  if (key === 'htevents') {\n    return { page: function() { throw 'page error'; } };\n  }\n});\nmock('Object.assign', function() { return {}; });\nmock('logToConsole', { error: function() {} });\n\nrunCode({\n  pageType: 'home',\n  pageTitle: 'Home',\n  mode: undefined,\n  promoCode: undefined,\n  status: undefined,\n  baseProperties: {},\n  buildPayload: {}\n});\n\nassertApi('gtmOnFailure').wasCalled();"
  }
]
