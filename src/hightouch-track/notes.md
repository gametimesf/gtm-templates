Replaces: hightouch-catchall.html, hightouch-click.html (Custom HTML tags)

Prerequisite: Error Bridge Custom HTML tag must fire before this tag (All Pages, high priority).

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
