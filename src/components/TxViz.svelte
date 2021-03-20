<script>
  import { onMount } from 'svelte'
  import TxController from '../controllers/TxController.js'
  import TxRender from './TxRender.svelte'
  import getTxStream from '../controllers/TxStream.js'
  import { darkMode, serverConnected, serverDelay, txQueueLength, txCount } from '../stores.js'
  import BitcoinBlock from '../models/BitcoinBlock.js'
  import config from '../config.js'

  let width = window.innerWidth - 20
  let height = window.innerHeight - 20
  let txController
  let blockCount = 0
  let running = false
  let txStream = getTxStream()

  onMount(() => {
    txController = new TxController({ width, height })

    txStream.subscribe('tx', tx => {
      txController.addTx(tx)
    })
    txStream.subscribe('block', block => {
      txController.addBlock(block)
    })
  })

  function resize () {
    width = window.innerWidth - 20
    height = window.innerHeight - 20
    txController.resize({
      width,
      height
    })
  }

  function fakeBlock () {
    txController.simulateBlock()
    // txController.addBlock(new BitcoinBlock({
    //   version: 'fake',
    //   id: Math.random(),
    //   value: 10000,
    //   prev_block: 'also_fake',
    //   merkle_root: 'merkle',
    //   timestamp: Date.now(),
    //   bits: 'none',
    //   txn_count: 20,
    //   txns: (new Array(100)).fill(0).map((x, i) => {
    //     return {
    //       version: 'fictional',
    //       value: Math.floor(Math.random() * 1000000) + 1,
    //       id: `fake_tx_${i}_${Math.random()}`
    //     }
    //   })
    // }))
  }

  function fakeTx (value) {
    txController.simulateDumpTx(1, value)
  }

  function fakeTxs () {
    txController.simulateDumpTx(200)
  }

  function toggleDark () {
    $darkMode = !$darkMode
  }

  $: connectionColor = $serverConnected ? ($serverDelay < 500 ? 'green' : 'amber') : 'red'
  $: connectionTitle = $serverConnected ? ($serverDelay < 500 ? 'Receiving live transactions' : 'Unstable connection') : 'No connection'
</script>

<style type="text/scss">
  .tx-area {
    position: fixed;
    width: 100%;
    height: 100%;
    top: 0;
    right: 0;
    left: 0;
    bottom: 0;
    overflow: hidden;
		display: flex;
		flex-direction: column;
		justify-content: center;
		align-items: center;
    background: var(--palette-a);
    transition: background 500ms;
  }

  .canvas-wrapper {
    position: relative;
    width: 100%;
    height: 100%;
  }

  .mempool-size-label {
    position: absolute;
    top: 30px;
    left: 30px;
    font-size: 20px;
    font-family: monospace;
    font-weight: bold;
    color: var(--palette-x);
    transition: color 500ms;
  }

  .sim-controls {
    position: absolute;
    top: 50px;
    left: 0;
    right: 0;
  }

  .status-bar {
    position: absolute;
    top: 20px;
    right: 20px;
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    justify-content: flex-end;

    .status-light {
      display: block;
      width: 10px;
      height: 10px;
      border-radius: 5px;

      &.red {
        background: red;
      }
      &.amber {
        background: yellow;
      }
      &.green {
        background: greenyellow;
      }
    }

    .stat-counter {
      margin-top: 5px;

      &.red {
        color: red;
      }
      &.amber {
        color: yellow;
      }
      &.green {
        color: greenyellow;
      }
    }
  }
</style>

<svelte:window on:resize={resize} />

<div class="tx-area" class:light-mode={!$darkMode}>
  <div class="canvas-wrapper">
    <TxRender controller={txController} />
  </div>
  {#if config.debug}
    <div class="sim-controls">
      <button on:click={() => fakeTx()}>TXN</button>
      <!-- <button on:click={() => fakeTx(10)}>10</button>
      <button on:click={() => fakeTx(100)}>100</button>
      <button on:click={() => fakeTx(1000)}>1000</button>
      <button on:click={() => fakeTx(10000)}>10000</button>
      <button on:click={() => fakeTx(100000)}>100000</button>
      <button on:click={() => fakeTx(1000000)}>1000000</button>
      <button on:click={() => fakeTx(10000000)}>10000000</button>
      <button on:click={() => fakeTx(100000000)}>1BTC</button> -->
      <button on:click={fakeTxs}>TXNS</button>
      <button on:click={fakeBlock}>BLOCK</button>
      <!-- <button on:click={toggleDark}>{$darkMode ? 'LIGHT' : 'DARK' }</button> -->
    </div>
  {/if}
  <div class="status-bar">
    <div class="status-light {connectionColor}" title={connectionTitle}></div>
    {#if config.debug}
      <span class="stat-counter {connectionColor}">{ $txQueueLength }</span>
      <span class="stat-counter {connectionColor}">{ $txCount }</span>
      {/if}
  </div>
</div>
