export default {
  dev: ENVIRONMENT === 'development',
  // devLightningRoot: 'http://localhost:4000',
  devLightningRoot: 'https://bits.monospace.live',
  debug: false,
  layoutHints: false,
  fps: true,
  websocket_path: '/ws/txs',
  localSocket: true,
  nofeed: false,
  txDelay: 10000,
  blockTimeout: 10000,
  donationAddress: "bc1qthanksv78zs5jnmysvmuuuzj09aklf8jmm49xl",
  donationHash: "5dfb3b419e38a1494f648337ce7052797b6fa4f2",
  lightningEnabled: true
}
