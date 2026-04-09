/**
 * @returns {void}
 */
function(){
    return function(eventName, eventProperties) {
      if (typeof htevents === 'undefined') return;
    
      var baseProperties = {{CJ - Base Properties}};
      var payload = {{CJ - Build Payload}};
      var properties = Object.assign({}, baseProperties, eventProperties, payload);
      
      try {
        htevents.track(eventName, properties);
      } catch(error) {
        console.error("Could not fire Hightouch " + eventName + " event", error);
      } 
    }
  }
  