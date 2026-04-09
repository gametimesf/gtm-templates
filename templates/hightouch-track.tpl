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

var callInWindow = require('callInWindow');
var copyFromWindow = require('copyFromWindow');
var logToConsole = require('logToConsole');

// After the Hightouch SDK loads it replaces window.htevents with a class instance
// that GTM's sandbox cannot copy. We use a bridge function (_htTrack) set by the
// init tag's e.ready() callback instead — plain functions survive the boundary.
if (!copyFromWindow('_htTrack')) {
  logToConsole('[Hightouch Track] SDK bridge not ready (_htTrack not found). Has the init tag fired and completed SDK load?');
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
                  {"type": 1, "string": "_htTrack"},
                  {"type": 8, "boolean": true},
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

scenarios:
- name: Fires track with merged properties via bridge function
  code: |-
    var trackedName, trackedProps;
    mock('copyFromWindow', function(key) {
      if (key === '_htTrack') { return function() {}; }
    });
    mock('callInWindow', function(fn, name, props) {
      if (fn === '_htTrack') {
        trackedName = name;
        trackedProps = props;
      }
    });

    runCode({
      eventName: 'search',
      interaction: 'button_click',
      sourcePageType: 'pdp',
      searchSessionId: 'sess-123',
      searchTerm: 'beyonce',
      baseProperties: { user_id: 'u1' },
      buildPayload: { payload_custom: 'val' }
    });

    assertApi('gtmOnSuccess').wasCalled();
- name: Calls gtmOnFailure when SDK bridge is not ready
  code: |-
    mock('copyFromWindow', function(key) { return undefined; });

    runCode({
      eventName: 'click',
      baseProperties: {},
      buildPayload: {}
    });

    assertApi('gtmOnFailure').wasCalled();
