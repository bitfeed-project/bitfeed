import config from '../config.js'

let analyticsEnabled = false

export default {
  init: function () {
    analyticsEnabled = true
    var _paq = window._paq = window._paq || [];
    /* tracker methods like "setCustomDimension" should be called before "trackPageView" */
    _paq.push(['trackPageView']);
    _paq.push(['enableLinkTracking']);
    _paq.push(['enableHeartBeatTimer']);
    (function() {
      var u="//matomo.monospace.live/";
      _paq.push(['setTrackerUrl', u+'matomo.php']);
      _paq.push(['setSiteId', config.dev ? '2' : '1']);
      var d=document, g=d.createElement('script'), s=d.getElementsByTagName('script')[0];
      g.type='text/javascript'; g.async=true; g.src=u+'matomo.js'; s.parentNode.insertBefore(g,s);
    })();
  },

  trackEvent: function (category, action, name, value) {
    if (analyticsEnabled) {
      if (config.dev) console.log('tracking event: ', {category, action, name, value})
      if (_paq) {
        _paq.push(['trackEvent', category, action, name, value]);
      }
    }
  }
}
