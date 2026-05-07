___INFO___

{
  "displayName": "Datadog RUM",
  "description": "Calls DD_RUM.addAction(), DD_RUM.setUser(), or DD_RUM.setAccount() with a context/properties object. Select the method from the dropdown — Action Name is only required for addAction.",
  "categories": ["ANALYTICS"],
  "id": "cvt_datadog_rum",
  "type": "TAG",
  "version": 1,
  "containerContexts": ["WEB"]
}

___TEMPLATE_PARAMETERS___

[
  {
    "type": "SELECT",
    "name": "method",
    "displayName": "Method",
    "simpleValueType": true,
    "help": "The DD_RUM method to call.",
    "alwaysInSummary": true,
    "selectItems": [
      {"value": "addAction", "displayValue": "addAction"},
      {"value": "setUser",   "displayValue": "setUser"},
      {"value": "setAccount","displayValue": "setAccount"}
    ],
    "defaultValue": "addAction"
  },
  {
    "type": "TEXT",
    "name": "actionName",
    "displayName": "Action Name",
    "simpleValueType": true,
    "help": "The RUM action name passed as the first argument to DD_RUM.addAction() — must match exactly what Datadog expects (e.g. 'Checkout Started', 'Purchase', 'Search').",
    "alwaysInSummary": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "enablingConditions": [
      {
        "paramName": "method",
        "paramValue": "addAction",
        "type": "EQUALS"
      }
    ]
  },
  {
    "type": "SIMPLE_TABLE",
    "name": "context",
    "displayName": "Context / Properties",
    "help": "Flat key-value pairs passed as the object argument. Values can reference GTM variables (e.g. {{DLV - Total Price}}). For computed or conditional values (e.g. value || undefined to omit falsy keys), use the Payload field instead.",
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
    "help": "Reference a Custom JavaScript variable returning a plain object. Merged on top of Context — payload wins on key conflicts. Use this for conditional or computed values the Context table cannot express, e.g: function() { return { user_id: {{DLV - User ID}} || undefined }; }"
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

if (!copyFromWindow('DD_RUM')) {
  logToConsole('[Datadog RUM] DD_RUM not found on window');
  reportError('[GTM:error] DD_RUM not found on window', { template: 'datadog-rum', method: data.method, actionName: data.actionName });
  data.gtmOnFailure();
  return;
}

var context = {};
var rows = data.context || [];
for (var i = 0; i < rows.length; i++) {
  if (rows[i].key) {
    context[rows[i].key] = rows[i].value;
  }
}

var payload = data.buildPayload || {};
for (var key in payload) {
  context[key] = payload[key];
}

logToConsole('[Datadog RUM]', data.method, data.actionName, context);

if (data.method === 'setUser') {
  callInWindow('DD_RUM.setUser', context);
} else if (data.method === 'setAccount') {
  callInWindow('DD_RUM.setAccount', context);
} else {
  callInWindow('DD_RUM.addAction', data.actionName, context);
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
                  {"type": 1, "string": "DD_RUM"},
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
                  {"type": 1, "string": "DD_RUM.addAction"},
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
                  {"type": 1, "string": "DD_RUM.setUser"},
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
                  {"type": 1, "string": "DD_RUM.setAccount"},
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

Replaces: Datadog RUM - Initiate Checkout, Datadog RUM - Purchase, Datadog RUM - Search
Covers:   Datadog RUM - ID User (split into two tag instances: one setUser, one setAccount)

Prerequisite: Error Bridge Custom HTML tag must fire before this tag (All Pages, high priority).

Method dropdown:
  addAction  -> DD_RUM.addAction(actionName, context)
  setUser    -> DD_RUM.setUser(context)
  setAccount -> DD_RUM.setAccount(context)

Action Name field is only shown when addAction is selected.

Tag instance configuration:

Datadog RUM - Initiate Checkout:
  Method      -> addAction
  Action Name -> Checkout Started
  Context:
    currency    -> USD
    listing_id  -> {{CJ - Dynamic - Listing ID}}
    quantity    -> {{DLV - Seat Quantity}}
    value       -> {{DLV - Total Price}}
  Payload     -> {{CJ - DD RUM Checkout Context}}

Datadog RUM - Purchase:
  Method      -> addAction
  Action Name -> Purchase
  Context:
    currency    -> USD
    event_id    -> {{CJ - Dynamic - Event ID}}
    listing_id  -> {{CJ - Dynamic - Listing ID}}
    quantity    -> {{DLV - Seat Quantity}}
    value       -> {{DLV - Total Price}}
  Payload     -> {{CJ - DD RUM Purchase Context}}

Datadog RUM - Search:
  Method      -> addAction
  Action Name -> Search
  Context:
    search_term -> {{DLV - Search Term}}
  Payload     -> {{CJ - DD RUM Search Context}}

Datadog RUM - ID User (setUser instance):
  Method      -> setUser
  Context:
    id    -> {{DLV - User ID}}
    email -> {{DLV - User Email}}

Datadog RUM - ID User (setAccount instance):
  Method      -> setAccount
  Context:
    id   -> {{DLV - Account ID}}
  Setup tag -> configure as setup tag for the setUser instance

Note on || undefined:
  The original tags use value || undefined to omit keys when the GTM variable
  resolves to a falsy value. The Context table always includes the key even
  if the value is empty. Use a Payload Custom JS variable for any property
  that should be omitted when falsy.

___TESTS___

scenarios:
- name: Fires addAction with merged context
  code: |-
    var calledWith = {};
    mock('copyFromWindow', function(key) {
      if (key === 'DD_RUM') { return {}; }
    });
    mock('callInWindow', function(fn, actionName, ctx) {
      calledWith = { fn: fn, actionName: actionName, ctx: ctx };
    });
    
    runCode({
      method: 'addAction',
      actionName: 'Checkout Started',
      context: [
        { key: 'currency', value: 'USD' },
        { key: 'value', value: '99.00' }
      ],
      buildPayload: { user_id: 'u-123' }
    });
    
    assertApi('gtmOnSuccess').wasCalled();
- name: Fires setUser with context object
  code: |-
    var calledWith = {};
    mock('copyFromWindow', function(key) {
      if (key === 'DD_RUM') { return {}; }
    });
    mock('callInWindow', function(fn, ctx) {
      calledWith = { fn: fn, ctx: ctx };
    });
    
    runCode({
      method: 'setUser',
      context: [{ key: 'id', value: 'user-123' }],
      buildPayload: {}
    });
    
    assertApi('gtmOnSuccess').wasCalled();
- name: Calls gtmOnFailure and reports error when DD_RUM not found
  code: |-
    var errorReported = false;
    mock('copyFromWindow', function(key) { return undefined; });
    mock('callInWindow', function(fn) {
      if (fn === '_reportError') { errorReported = true; }
    });
    
    runCode({
      method: 'addAction',
      actionName: 'Purchase',
      context: [],
      buildPayload: {}
    });
    
    assertApi('gtmOnFailure').wasCalled();
