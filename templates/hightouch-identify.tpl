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

var copyFromWindow = require('copyFromWindow');
var logToConsole = require('logToConsole');

var htevents = copyFromWindow('htevents');
if (!htevents) {
  logToConsole.log('htevents undefined');
  data.gtmOnFailure();
  return;
}

htevents.setAnonymousId(data.deviceId);

var userId = data.userId || data.userIdFallback;
var traits = {
  email: data.email,
  phone: data.phone,
  deviceId: data.deviceId,
  sessionId: data.sessionId
};

try {
  htevents.identify(userId, traits);
  data.gtmOnSuccess();
} catch (error) {
  logToConsole.error("Could not fire Hightouch 'Identify' event", error);
  data.gtmOnFailure();
}

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

[
  {
    "name": "Sets anonymous ID and fires htevents.identify with traits",
    "code": "var anonymousIdSet, identifyCalledWith;\nmock('copyFromWindow', function(key) {\n  if (key === 'htevents') {\n    return {\n      setAnonymousId: function(id) { anonymousIdSet = id; },\n      identify: function(userId, traits) { identifyCalledWith = { userId: userId, traits: traits }; }\n    };\n  }\n});\nmock('logToConsole', { log: function() {}, error: function() {} });\n\nrunCode({\n  deviceId: 'device-abc',\n  userId: 'user-123',\n  userIdFallback: 'cookie-456',\n  email: 'user@example.com',\n  phone: '+15551234567',\n  sessionId: 'sess-xyz'\n});\n\nassertApi('gtmOnSuccess').wasCalled();"
  },
  {
    "name": "Falls back to userIdFallback when userId is falsy",
    "code": "var resolvedUserId;\nmock('copyFromWindow', function(key) {\n  if (key === 'htevents') {\n    return {\n      setAnonymousId: function() {},\n      identify: function(userId, traits) { resolvedUserId = userId; }\n    };\n  }\n});\nmock('logToConsole', { log: function() {}, error: function() {} });\n\nrunCode({\n  deviceId: 'device-abc',\n  userId: '',\n  userIdFallback: 'cookie-fallback',\n  email: undefined,\n  phone: undefined,\n  sessionId: undefined\n});\n\nassertApi('gtmOnSuccess').wasCalled();"
  },
  {
    "name": "Calls gtmOnFailure when htevents is not on window",
    "code": "mock('copyFromWindow', function(key) { return undefined; });\nmock('logToConsole', { log: function() {}, error: function() {} });\n\nrunCode({\n  deviceId: 'device-abc',\n  userId: 'user-123',\n  userIdFallback: 'cookie-456',\n  email: 'user@example.com',\n  phone: undefined,\n  sessionId: 'sess-xyz'\n});\n\nassertApi('gtmOnFailure').wasCalled();"
  }
]
