import config from '../config.js'
import BitcoinTx from '../models/BitcoinTx.js'

const apiRoot = `${config.backend ? config.backend : window.location.host }${config.backendPort ? ':' + config.backendPort : ''}`

export default {
  root: apiRoot,
  websocketUri: `${config.secureSocket ? 'wss://' : 'ws://'}${apiRoot}/ws/txs`,
  uri: `${config.secureSocket ? 'https://' : 'http://'}${apiRoot}`,
}
