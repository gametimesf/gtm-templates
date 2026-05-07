___INFO___

{
  "displayName": "Hightouch Identify",
  "description": "Sets the Hightouch anonymous ID and fires an htevents.identify() call with user traits. Replaces the Custom HTML identify tag.",
  "categories": ["ANALYTICS"],
  "id": "cvt_hightouch_identify",
  "type": "TAG",
  "version": 1,
  "containerContexts": ["WEB"]
}

___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "deviceId",
    "displayName": "Device ID (Anonymous ID)",
    "simpleValueType": true,
    "help": "Reference {{Device ID}}. Used as the anonymous ID via htevents.setAnonymousId() and also included in traits as deviceId.",
    "alwaysInSummary": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "userId",
    "displayName": "User ID",
    "simpleValueType": true,
    "help": "Reference {{CJ - User ID}}. If this resolves to a falsy value, the User ID Fallback is used instead."
  },
  {
    "type": "TEXT",
    "name": "email",
    "displayName": "Email",
    "simpleValueType": true,
    "help": "Reference {{DLV - User Email}}. Included in identify traits."
  },
  {
    "type": "TEXT",
    "name": "phone",
    "displayName": "Phone",
    "simpleValueType": true,
    "help": "Reference {{DLV - User Phone}}. Included in identify traits."
  },
  {
    "type": "TEXT",
    "name": "sessionId",
    "displayName": "Session ID",
    "simpleValueType": true,
    "help": "Reference {{Cookie - gt_sid}}. Included in identify traits."
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
                  {"type": 1, "string": "_htIdentify"},
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
                  {"type": 1, "string": "_htSetAnonId"},
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

Replaces: hightouch-identify.html (Custom HTML tag)

Prerequisite: Error Bridge Custom HTML tag must fire before this tag (All Pages, high priority).

Parameter mapping:
  Device ID (Anonymous ID) -> {{Device ID}}
  User ID                  -> {{CJ - User ID}}
  Email                    -> {{DLV - User Email}}
  Phone                    -> {{DLV - User Phone}}
  Session ID               -> {{Cookie - gt_sid}}

___TESTS___

scenarios:
- name: Calls gtmOnFailure and reports error when bridge not ready
  code: |-
    var errorReported = false;
    mock('copyFromWindow', function(key) { return undefined; });
    mock('callInWindow', function(fn) {
      if (fn === '_reportError') { errorReported = true; }
    });
    
    runCode({
      deviceId: 'device-abc',
      userId: 'user-123',
      email: 'user@example.com',
      sessionId: 'sess-xyz'
    });
    
    assertApi('gtmOnFailure').wasCalled();
- name: Sets anonymous ID and fires identify with traits via bridge functions
  code: |-
    var anonIdSet, identifyCalledWith;
    mock('copyFromWindow', function(key) {
      if (key === '_htIdentify') { return function() {}; }
    });
    mock('callInWindow', function(fn, a, b) {
      if (fn === '_htSetAnonId') { anonIdSet = a; }
      if (fn === '_htIdentify') { identifyCalledWith = { userId: a, traits: b }; }
    });
    
    runCode({
      deviceId: 'device-abc',
      userId: 'user-123',
      email: 'user@example.com',
      phone: '+15551234567',
      sessionId: 'sess-xyz'
    });
    
    assertApi('gtmOnSuccess').wasCalled();
