// Inject process.env variables
if (!window.injected) window.injected = {}
if (!window.injected.TARGET) window.injected.TARGET = INJECTED_TARGET
if (!window.injected.OVERRIDE_BACKEND_HOST) window.injected.OVERRIDE_BACKEND_HOST = INJECTED_HOST
if (!window.injected.OVERRIDE_BACKEND_PORT) window.injected.OVERRIDE_BACKEND_PORT = INJECTED_PORT

function getInjectedEnv (key, fallback) {
  if (window.injected[key] != null && window.injected[key] != "") {
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
  noTxFeed: false,
  noBlockFeed: false,
  // Minimum delay in ms before newly recieved transactions enter the visualization
  txDelay: 3000,
  donationsEnabled: true,
  // Enables the message bar
  messagesEnabled: true,
  // Delay in ms between message bar rotations
  alertDuration: 20000,
}
