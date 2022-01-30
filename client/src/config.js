function getInjectedEnv (key, fallback) {
  if (window.injected && window.injected[key] != null) {
    return window.injected[key]
  }
  return fallback
}

export default {
  dev: ENVIRONMENT === 'development',
  // external API for processing donations, retrieving donor info & message bar content
  donationRoot: 'https://donate.monospace.live',
  // enables some additional logging & debugging tools
  debug: false,
  // enables an additional square packing algorithm debugging tool
  layoutHints: false,
  // if this instance is public-facing, enables e.g. analytics
  target: getInjectedEnv('TARGET'),
  public: (getInjectedEnv('TARGET', 'dev') === "public"),
  // host & port of the backend API websocket server
  backend: getInjectedEnv('OVERRIDE_BACKEND_HOST'), // do not include the protocol
  backendPort: getInjectedEnv('OVERRIDE_BACKEND_PORT'),
  // Whether to connect to the backend server over ws:// or wss://
  secureSocket: (window.location.protocol === 'https:'),
  // Disables the transaction feed
  nofeed: false,
  // Minimum delay in ms before newly recieved transactions enter the visualization
  txDelay: 10000,
  donationsEnabled: true,
  // Enables the message bar
  messagesEnabled: true,
  // Delay in ms between message bar rotations
  alertDuration: 20000,
}
