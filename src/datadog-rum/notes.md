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
