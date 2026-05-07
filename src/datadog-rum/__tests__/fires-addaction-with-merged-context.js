/**
 * @name Fires addAction with merged context
 */
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
