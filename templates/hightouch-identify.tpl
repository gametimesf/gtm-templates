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
    "name": "userIdFallback",
    "displayName": "User ID Fallback",
    "simpleValueType": true,
    "help": "Reference {{Cookie - gt_id}}. Used when User ID is falsy."
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

var callInWindow = require('callInWindow');
var copyFromWindow = require('copyFromWindow');
var logToConsole = require('logToConsole');

// After the Hightouch SDK loads it replaces window.htevents with a class instance
// that GTM's sandbox cannot copy. We use bridge functions (_htSetAnonId, _htIdentify)
// set by the init tag's e.ready() callback instead — plain functions survive the boundary.
if (!copyFromWindow('_htIdentify')) {
  logToConsole('[Hightouch Identify] SDK bridge not ready (_htIdentify not found). Has the init tag fired and completed SDK load?');
  data.gtmOnFailure();
  return;
}

callInWindow('_htSetAnonId', data.deviceId);

var userId = data.userId || data.userIdFallback;
var traits = {
  email: data.email,
  phone: data.phone,
  deviceId: data.deviceId,
  sessionId: data.sessionId
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

Parameter mapping:
  Device ID (Anonymous ID) -> {{Device ID}}
  User ID                  -> {{CJ - User ID}}
  User ID Fallback         -> {{Cookie - gt_id}}
  Email                    -> {{DLV - User Email}}
  Phone                    -> {{DLV - User Phone}}
  Session ID               -> {{Cookie - gt_sid}}

The User ID falls back to {{Cookie - gt_id}} when {{CJ - User ID}} is falsy
(undefined, null, empty string), preserving the || behaviour from the original tag.

___TESTS___

scenarios:
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
      userIdFallback: 'cookie-456',
      email: 'user@example.com',
      phone: '+15551234567',
      sessionId: 'sess-xyz'
    });

    assertApi('gtmOnSuccess').wasCalled();
- name: Falls back to userIdFallback when userId is falsy
  code: |-
    var resolvedUserId;
    mock('copyFromWindow', function(key) {
      if (key === '_htIdentify') { return function() {}; }
    });
    mock('callInWindow', function(fn, a, b) {
      if (fn === '_htIdentify') { resolvedUserId = a; }
    });

    runCode({
      deviceId: 'device-abc',
      userId: '',
      userIdFallback: 'cookie-fallback'
    });

    assertApi('gtmOnSuccess').wasCalled();
- name: Calls gtmOnFailure when SDK bridge is not ready
  code: |-
    mock('copyFromWindow', function(key) { return undefined; });

    runCode({
      deviceId: 'device-abc',
      userId: 'user-123',
      userIdFallback: 'cookie-456',
      email: 'user@example.com',
      sessionId: 'sess-xyz'
    });

    assertApi('gtmOnFailure').wasCalled();
