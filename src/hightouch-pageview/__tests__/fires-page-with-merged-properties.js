/**
 * @name Fires page with merged properties via bridge function
 */
var calledWith = {};
mock('copyFromWindow', function(key) {
  if (key === '_htPage') { return function() {}; }
});
mock('callInWindow', function(fn, pageType, pageTitle, props) {
  if (fn === '_htPage') {
    calledWith = { pageType: pageType, pageTitle: pageTitle, props: props };
  }
});

runCode({
  pageType: 'pdp',
  pageTitle: 'Event Detail',
  mode: 'buy',
  promoCode: 'SAVE10',
  status: 'available',
  baseProperties: { user_id: 'u1' },
  buildPayload: { payload_ref: 'home' }
});

assertApi('gtmOnSuccess').wasCalled();
