export default {
  dev: ENVIRONMENT === 'development',
  donationRoot: 'http://localhost:3001',
  debug: false,
  layoutHints: false,
  fps: true,
  websocket_path: '/ws/txs',
  localSocket: false,
  nofeed: false,
  txDelay: 10000,
  donationsEnabled: true,
  alertDuration: 20000,
}
