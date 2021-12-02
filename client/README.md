# Bitfeed

This repo hosts the code behind Bitfeed (bits.monospace.live), which is a live visualization of Bitcoin network activity, focusing on the journey from unconfirmed transactions to confirmed blocks.

## Installing

Install on a local machine or hardware node to run a personal copy of the visualization.

### Prerequisites

The Bitfeed server relies on a local instance of Bitcoin Core, compiled with ZeroMQ enabled. Fee-related data requires an unpruned node with txindex=1. 

## Contributing

Install the dependencies...

```bash
npm install
```

...then start [Rollup](https://rollupjs.org):

```bash
npm run dev
```

Navigate to [localhost:5000](http://localhost:5000). You should see your app running. Edit a component file in `src`, save it, and reload the page to see your changes.



#### Building and running in production mode

To create an optimised version of the app:

```bash
npm run build
```