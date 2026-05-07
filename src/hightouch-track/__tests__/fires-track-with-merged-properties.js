/**
 * @name Fires track with merged properties via bridge function
 */
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
