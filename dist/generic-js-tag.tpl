___INFO___

{
  "displayName": "Generic JS Tag",
  "description": "Calls any window function (e.g. fbq, spdt, ttq.track) with an event name and flat key-value properties. Covers SDKs that follow a fn(eventName, props) or fn(method, eventName, props) call pattern. Does not support async operations.",
  "categories": ["ANALYTICS", "ADVERTISING"],
  "id": "cvt_generic_js_tag",
  "type": "TAG",
  "version": 1,
  "containerContexts": ["WEB"]
}

___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "windowFunction",
    "displayName": "Window Function",
    "simpleValueType": true,
    "help": "The global function to call. Use a plain name for top-level functions (e.g. fbq, spdt) or dot notation for nested methods (e.g. ttq.track). The root object is checked for existence before the call is made.",
    "alwaysInSummary": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "methodArg",
    "displayName": "Method Arg (optional)",
    "simpleValueType": true,
    "help": "Some SDKs require a method type as the first argument before the event name (e.g. 'track' for fbq, which is called as fbq('track', eventName, props)). Leave blank for SDKs that use fn(eventName, props) directly."
  },
  {
    "type": "TEXT",
    "name": "eventName",
    "displayName": "Event Name",
    "simpleValueType": true,
    "help": "The event name passed to the function (e.g. ViewContent, purchase, PlaceAnOrder).",
    "alwaysInSummary": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "SIMPLE_TABLE",
    "name": "properties",
    "displayName": "Properties",
    "help": "Flat key-value pairs passed as the properties object. Values can reference GTM variables (e.g. {{DLV - Total Price}}) or be literal strings. For nested structures (arrays, nested objects), use the Payload field instead.",
    "simpleTableColumns": [
      {
        "defaultValue": "",
        "displayName": "Key",
        "name": "key",
        "type": "TEXT"
      },
      {
        "defaultValue": "",
        "displayName": "Value",
        "name": "value",
        "type": "TEXT",
        "valueHint": "{{GTM Variable}} or literal"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "buildPayload",
    "displayName": "Payload (optional)",
    "simpleValueType": true,
    "help": "Reference a Custom JavaScript variable that returns a plain object. Merged on top of Properties — payload values win on key conflicts. Use this for nested structures (e.g. TikTok's contents array) that cannot be expressed in the flat Properties table."
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
                  {"type": 1, "string": "fbq"},
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
                  {"type": 1, "string": "spdt"},
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
                  {"type": 1, "string": "ttq"},
                  {"type": 8, "boolean": true},
                  {"type": 8, "boolean": false},
                  {"type": 8, "boolean": false}
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
                  {"type": 1, "string": "ttq.track"},
                  {"type": 8, "boolean": false},
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
                  {"type": 1, "string": "DD_RUM"},
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
                  {"type": 1, "string": "ire"},
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
                  {"type": 1, "string": "podscribe"},
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
                  {"type": 1, "string": "uetq"},
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
                  {"type": 1, "string": "_uetqPush"},
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

A single generic tag for third-party SDKs that follow a synchronous
fn(eventName, props) or fn(method, eventName, props) call pattern.

Prerequisite: Error Bridge Custom HTML tag must fire before this tag (All Pages, high priority).

NOT suitable for:
  - Async operations (Promises, crypto.subtle) — keep those as Custom HTML
  - SDKs that require DOM manipulation during the call

Adding a new vendor:
  GTM does not support wildcard permissions — each vendor's global must be
  explicitly declared in permissions.json. To add a new vendor:
  1. Add an entry to src/generic-js-tag/permissions.json
  2. If using dot notation (e.g. ttq.track), add two entries: root object (read only)
     and the method (execute only)
  3. Run npm run build
  4. Re-import dist/generic-js-tag.tpl into GTM and approve the new permission

Current vendors declared: fbq (Meta), spdt (Spotify), ttq (TikTok read), ttq.track (TikTok execute),
                          DD_RUM (Datadog), ire (Impact Radius), podscribe (Podscribe),
                          uetq (Microsoft Ads — raw), _uetqPush (Microsoft Ads — bridge)

Note: dot-notation calls (e.g. ttq.track) require a separate execute entry from the root
object read entry. Add both when registering a new nested method.

___TESTS___

scenarios:
- name: Calls fn(eventName, props) when no methodArg set
  code: |-
    var calledWith = {};
    mock('copyFromWindow', function(key) {
      if (key === 'spdt') { return function() {}; }
    });
    mock('callInWindow', function(fn, a, b) {
      calledWith = { fn: fn, eventName: a, props: b };
    });
    
    runCode({
      windowFunction: 'spdt',
      eventName: 'viewProduct',
      properties: [{ key: 'currency', value: 'USD' }, { key: 'product_id', value: '123' }],
      buildPayload: {}
    });
    
    assertApi('gtmOnSuccess').wasCalled();
- name: Calls fn(methodArg, eventName, props) when methodArg is set
  code: |-
    var calledWith = {};
    mock('copyFromWindow', function(key) {
      if (key === 'fbq') { return function() {}; }
    });
    mock('callInWindow', function(fn, a, b, c) {
      calledWith = { fn: fn, method: a, eventName: b, props: c };
    });
    
    runCode({
      windowFunction: 'fbq',
      methodArg: 'track',
      eventName: 'ViewContent',
      properties: [{ key: 'content_ids', value: 'evt-456' }],
      buildPayload: {}
    });
    
    assertApi('gtmOnSuccess').wasCalled();
- name: Calls gtmOnFailure and reports error when root function not found on window
  code: |-
    var errorReported = false;
    mock('copyFromWindow', function(key) { return undefined; });
    mock('callInWindow', function(fn) {
      if (fn === '_reportError') { errorReported = true; }
    });
    
    runCode({
      windowFunction: 'spdt',
      eventName: 'viewProduct',
      properties: [],
      buildPayload: {}
    });
    
    assertApi('gtmOnFailure').wasCalled();
