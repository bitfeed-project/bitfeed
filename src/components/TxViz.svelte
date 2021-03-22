<script>
  import { onMount } from 'svelte'
  import TxController from '../controllers/TxController.js'
  import TxRender from './TxRender.svelte'
  import getTxStream from '../controllers/TxStream.js'
  import { settings, serverConnected, serverDelay, txQueueLength, txCount, frameRate, blockVisible, currentBlock } from '../stores.js'
  import BitcoinBlock from '../models/BitcoinBlock.js'
  import BlockInfo from '../components/BlockInfo.svelte'
  import Settings from '../components/Settings.svelte'
  import config from '../config.js'

  let width = window.innerWidth - 20
  let height = window.innerHeight - 20
  let txController
  let blockCount = 0
  let running = false

  let lastFrameUpdate = 0
  let frameRateLabel = ''

  let txStream
  if (!config.nofeed) txStream = getTxStream()

  onMount(() => {
    txController = new TxController({ width, height })

    if (!config.nofeed) {
      txStream.subscribe('tx', tx => {
        txController.addTx(tx)
      })
      txStream.subscribe('block', block => {
        txController.addBlock(block)
      })
    }
  })

  function resize () {
    width = window.innerWidth - 20
    height = window.innerHeight - 20
    txController.resize({
      width,
      height
    })
  }

  function hideBlock () {
    if (txController) {
      txController.hideBlock()
    }
  }

  function fakeBlock () {
    const block = txController.simulateBlock()
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

  $: connectionColor = ($serverConnected && $serverDelay < 5000) ? ($serverDelay < 500 ? 'good' : 'ok') : 'bad'
  $: connectionTitle = ($serverConnected && $serverDelay < 5000) ? ($serverDelay < 500 ? 'Streaming live transactions' : 'Unstable connection') : 'Disconnected'
  $: {
    if (lastFrameUpdate + 250 < Date.now()) {
      frameRateLabel = Number($frameRate).toFixed(1) + ' FPS'
      lastFrameUpdate = Date.now()
    }
  }
  $: frameRateColor = $frameRate > 40 ? 'good' : ($frameRate > 20 ? 'ok' : 'bad')

	const debounce = v => {
		clearTimeout(timer);
		timer = setTimeout(() => {
			val = v;
		}, 750);
	}
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
    display: flex;
    justify-content: center;
    align-items: center;
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
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    justify-content: flex-end;

    &.right {
      right: 20px;
    }

    &.left {
      left: 20px
    }

    .status-light {
      display: block;
      width: 10px;
      height: 10px;
      border-radius: 5px;

      &.bad {
        background: var(--palette-bad);
      }
      &.ok {
        background: var(--palette-ok);
      }
      &.good {
        background: var(--palette-good);
      }
    }

    .stat-counter {
      margin-top: 5px;

      &.bad {
        color: var(--palette-bad);
      }
      &.ok {
        color: var(--palette-ok);
      }
      &.good {
        color: var(--palette-good);
      }
    }
  }

  .block-area-wrapper {
    position: relative;
    width: 75vw;
    max-width: 50vh;

    .block-area {
      padding-top: 100%;
    }
  }
</style>

<svelte:window on:resize={resize} />

<div class="tx-area" class:light-mode={!$settings.darkMode}>
  <div class="canvas-wrapper">
    <TxRender controller={txController} />

    <div class="block-area-wrapper">
      <div class="block-area">
        <BlockInfo block={$currentBlock} visible={$blockVisible} on:hideBlock={hideBlock} />
      </div>
    </div>
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
    </div>
  {/if}
  <div class="status-bar right">
    <div class="status-light {connectionColor}" title={connectionTitle}></div>
    {#if config.debug}
      <span class="stat-counter {connectionColor}">{ $serverDelay } ms</span>
      <span class="stat-counter {connectionColor}">{ $txQueueLength }</span>
      <span class="stat-counter {connectionColor}">{ $txCount }</span>
      {/if}
  </div>
  {#if $settings.showFPS }
    <div class="status-bar left">
      <span class="stat-counter {frameRateColor}">{ frameRateLabel }</span>
    </div>
  {/if}

  <Settings />
</div>
