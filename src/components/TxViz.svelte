<script>
  import { onMount } from 'svelte'
  import TxController from '../controllers/TxController.js'
  import TxRender from './TxRender.svelte'
  import getTxStream from '../controllers/TxStream.js'
  import { settings, serverConnected, serverDelay, txQueueLength, txCount, frameRate, blockVisible, currentBlock, devEvents } from '../stores.js'
  import BitcoinBlock from '../models/BitcoinBlock.js'
  import BlockInfo from '../components/BlockInfo.svelte'
  import Sidebar from '../components/Sidebar.svelte'
  import DonationBar from '../components/DonationBar.svelte'
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

    $devEvents.addOneCallback = fakeTx
    $devEvents.addManyCallback = fakeTxs
    $devEvents.addBlockCallback = fakeBlock
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
    pointer-events: none;

    button {
      pointer-events: all;
    }
  }

  .top-bar {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    width: 100%;
    display: flex;
    flex-direction: row;
    justify-content: space-between;
    align-items: flex-start;

    .status, .spacer {
      width: 6.25rem;
    }

    .status {
      text-align: left;
      padding: 1rem;
      flex-shrink: 0;

      .status-light {
        display: inline-block;
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
  }



  .block-area-wrapper {
    height: 100%;
    display: flex;
    flex-direction: column;
    pointer-events: none;

    .spacer {
      flex: 1;
    }

    .block-area-outer {
      position: relative;
      flex: 0;
      width: 75vw;
      max-width: 40vh;
      margin: auto;

      .block-area {
        padding-top: 100%;
      }
    }
  }
</style>

<svelte:window on:resize={resize} />

<div class="tx-area" class:light-mode={!$settings.darkMode}>
  <div class="canvas-wrapper">
    <TxRender controller={txController} />

    <div class="block-area-wrapper">
      <div class="spacer"></div>
      <div class="block-area-outer">
        <div class="block-area">
          <BlockInfo block={$currentBlock} visible={$blockVisible} on:hideBlock={hideBlock} />
        </div>
      </div>
      <div class="spacer"></div>
      <div class="spacer"></div>
    </div>
  </div>

  <div class="top-bar">
    <div class="status">
      {#if $settings.showNetworkStatus }
        <div class="status-light {connectionColor}" title={connectionTitle}></div>
      {/if}
      {#if $settings.showFPS }
        <span class="stat-counter {frameRateColor}">{ frameRateLabel }</span>
      {/if}
    </div>
    {#if $settings.showDonation }
      <DonationBar />
    {/if}
    <div class="spacer" />
  </div>

  <Sidebar />
</div>
