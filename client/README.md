## Building and Running the Bitfeed Front End Client

#### Prerequisites
 - [Node](https://nodejs.dev/download/)
 - NPM
 - Nginx (production deployment only)
 - [API server](https://github.com/bitfeed-project/bitfeed/blob/master/server)

#### Configuration

`client/src/config.js` exposes a number of configuration options, mostly useful for local development.

When developing the front end, you can point at the hosted backend API server instead of running your own full node and server instance by setting `backend` to `"bits.monospace.live"` and `backendPort` to `null`.

#### Installation

```shell
npm install
```

#### Running in development
```shell
npm run dev
```

#### Building for production
```shell
npm run build
```
