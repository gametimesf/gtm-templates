/**
 * @name Calls fn(eventName, props) when no methodArg set
 */
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
