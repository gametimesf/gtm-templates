___INFO___

{
  "displayName": "Hightouch Track",
  "description": "Fires an htevents.track() call. Covers all track-type events (catchall, click, etc.). Configure one tag instance per event type using the optional property parameters.",
  "categories": ["ANALYTICS"],
  "id": "cvt_hightouch_track",
  "type": "TAG",
  "version": 1,
  "containerContexts": ["WEB"]
}

___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "eventName",
    "displayName": "Event Name",
    "simpleValueType": true,
    "help": "The name of the event to track. Use {{Event}} for the current GTM event name, or enter a literal string (e.g. 'click').",
    "alwaysInSummary": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "interaction",
    "displayName": "Interaction",
    "simpleValueType": true,
    "help": "Reference {{CJ - Dynamic - Interaction}}. Leave blank if not applicable to this event type."
  },
  {
    "type": "TEXT",
    "name": "sourcePageType",
    "displayName": "Source Page Type",
    "simpleValueType": true,
    "help": "Reference {{CJ - Page Source}}."
  },
  {
    "type": "TEXT",
    "name": "targetPageType",
    "displayName": "Target Page Type",
    "simpleValueType": true,
    "help": "Reference {{DLV - Target Page}}. Used for click events. Leave blank for catchall/search events."
  },
  {
    "type": "TEXT",
    "name": "searchSessionId",
    "displayName": "Search Session ID",
    "simpleValueType": true,
    "help": "Reference {{DLV - Search Session ID}}. Used for search/catchall events. Leave blank for click events."
  },
  {
    "type": "TEXT",
    "name": "searchTerm",
    "displayName": "Search Term",
    "simpleValueType": true,
    "help": "Reference {{DLV - Search Term}}. Used for search/catchall events. Leave blank for click events."
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

// Only include properties that were actually configured for this tag instance.
// This prevents sending null/undefined keys to Hightouch for event types
// that don't use certain properties (e.g. click events don't need search_session_id).
var eventProperties = {};
if (data.interaction !== undefined)     eventProperties.interaction = data.interaction;
if (data.sourcePageType !== undefined)  eventProperties.source_page_type = data.sourcePageType;
if (data.targetPageType !== undefined)  eventProperties.target_page_type = data.targetPageType;
if (data.searchSessionId !== undefined) eventProperties.search_session_id = data.searchSessionId;
if (data.searchTerm !== undefined)      eventProperties.search_term = data.searchTerm;

// Merge order mirrors the original: base < event-specific < payload
var properties = objectAssign({}, data.baseProperties || {}, eventProperties, data.buildPayload || {});

try {
  htevents.track(data.eventName, properties);
  data.gtmOnSuccess();
} catch (error) {
  logToConsole.error('Could not fire Hightouch ' + data.eventName + ' event', error);
  data.gtmOnFailure();
}

___NOTES___

Replaces: hightouch-catchall.html, hightouch-click.html (Custom HTML tags)

Tag instance configuration:

Catchall tag:
  Event Name       -> {{Event}}
  Interaction      -> {{CJ - Dynamic - Interaction}}
  Source Page Type -> {{CJ - Page Source}}
  Search Session ID-> {{DLV - Search Session ID}}
  Search Term      -> {{DLV - Search Term}}
  Target Page Type -> (leave blank)
  Base Properties  -> {{CJ - Base Properties}}
  Payload          -> {{CJ - Build Payload}}

Click tag:
  Event Name       -> click  (literal string)
  Interaction      -> {{CJ - Dynamic - Interaction}}
  Source Page Type -> {{CJ - Page Source}}
  Target Page Type -> {{DLV - Target Page}}
  Search Session ID-> (leave blank)
  Search Term      -> (leave blank)
  Base Properties  -> {{CJ - Base Properties}}
  Payload          -> {{CJ - Build Payload}}

___TESTS___

[
  {
    "name": "Fires htevents.track with merged properties",
    "code": "var trackedName, trackedProps;\nmock('copyFromWindow', function(key) {\n  if (key === 'htevents') {\n    return {\n      track: function(name, props) {\n        trackedName = name;\n        trackedProps = props;\n      }\n    };\n  }\n});\nmock('Object.assign', function() {\n  var result = {};\n  for (var i = 0; i < arguments.length; i++) {\n    var src = arguments[i] || {};\n    for (var key in src) { result[key] = src[key]; }\n  }\n  return result;\n});\nmock('logToConsole', { error: function() {} });\n\nrunCode({\n  eventName: 'search',\n  interaction: 'button_click',\n  sourcePageType: 'pdp',\n  targetPageType: undefined,\n  searchSessionId: 'sess-123',\n  searchTerm: 'beyonce',\n  baseProperties: { user_id: 'u1' },\n  buildPayload: { payload_custom: 'val' }\n});\n\nassertApi('gtmOnSuccess').wasCalled();"
  },
  {
    "name": "Calls gtmOnFailure when htevents is not on window",
    "code": "mock('copyFromWindow', function(key) { return undefined; });\nmock('Object.assign', function() { return {}; });\nmock('logToConsole', { error: function() {} });\n\nrunCode({\n  eventName: 'click',\n  interaction: undefined,\n  sourcePageType: undefined,\n  targetPageType: undefined,\n  searchSessionId: undefined,\n  searchTerm: undefined,\n  baseProperties: {},\n  buildPayload: {}\n});\n\nassertApi('gtmOnFailure').wasCalled();"
  },
  {
    "name": "Calls gtmOnFailure when htevents.track throws",
    "code": "mock('copyFromWindow', function(key) {\n  if (key === 'htevents') {\n    return { track: function() { throw 'track error'; } };\n  }\n});\nmock('Object.assign', function() { return {}; });\nmock('logToConsole', { error: function() {} });\n\nrunCode({\n  eventName: 'failing_event',\n  interaction: undefined,\n  sourcePageType: undefined,\n  targetPageType: undefined,\n  searchSessionId: undefined,\n  searchTerm: undefined,\n  baseProperties: {},\n  buildPayload: {}\n});\n\nassertApi('gtmOnFailure').wasCalled();"
  }
]
