<script>
  import { onMount } from 'svelte'
  import TxController from '../controllers/TxController.js'
  import TxRender from './TxRender.svelte'
  import getTxStream from '../controllers/TxStream.js'
  import { settings, overlay, serverConnected, serverDelay, txQueueLength, txCount, mempoolCount, mempoolScreenHeight, frameRate, avgFrameRate, blockVisible, currentBlock, selectedTx, blockAreaSize, devEvents, devSettings } from '../stores.js'
  import BitcoinBlock from '../models/BitcoinBlock.js'
  import BlockInfo from '../components/BlockInfo.svelte'
  import TxInfo from '../components/TxInfo.svelte'
  import Sidebar from '../components/Sidebar.svelte'
  import AboutOverlay from '../components/AboutOverlay.svelte'
  import DonationOverlay from '../components/DonationOverlay.svelte'
  import SupportersOverlay from '../components/SupportersOverlay.svelte'
  import Alerts from '../components/alert/Alerts.svelte'
  import { integerFormat } from '../utils/format.js'
  import { exchangeRates, localCurrency, lastBlockId, showSupporters } from '../stores.js'
  import { formatCurrency } from '../utils/fx.js'
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

  $: {
    if ($blockVisible) {
      if (txController) txController.showBlock()
    } else {
      if (txController) txController.hideBlock()
    }
  }

  let modeLoaded = false
  let currentMode
  $: {
    if ($settings && currentMode != $settings.vbytes) {
      if (!modeLoaded) modeLoaded = true
      else changedMode($settings.vbytes)
      currentMode = $settings.vbytes
    }
  }

  onMount(() => {
    txController = new TxController({ width, height })

    if (!config.nofeed) {
      txStream.subscribe('tx', tx => {
        txController.addTx(tx)
      })
      txStream.subscribe('block', block => {
        if (block) {
          const added = txController.addBlock(block)
          if (added && added.id) $lastBlockId = added.id
        }
        txStream.sendMempoolRequest()
      })
      txStream.subscribe('mempool_count', count => {
        $mempoolCount = count
      })
    }

    $devEvents.addOneCallback = fakeTx
    $devEvents.addManyCallback = fakeTxs
    $devEvents.addBlockCallback = fakeBlock

    if (!$settings.showMessages) $settings.showMessages = true
  })

  function resize () {
    if (width !== window.innerWidth - 20 || height !== window.innerHeight - 20) {
      // don't force resize unless the viewport has actually changed
      width = window.innerWidth - 20
      height = window.innerHeight - 20
      txController.resize({
        width,
        height
      })
    }
  }

  function changedMode () {
    if (txController) {
      txController.redoLayout({
        width,
        height
      })
    }
  }

  function hideBlock () {
    $blockVisible = false
  }

  function fakeBlock () {
    const block = txController.simulateBlock()
    // txController.addBlock(new BitcoinBlock({
    //   version: 'fake',
    //   id: Math.random(),
    //   value: 10000,
    //   prev_block: 'also_fake',
    //   merkle_root: 'merkle',
    //   timestamp: performance.now(),
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
    if (lastFrameUpdate + 250 < performance.now()) {
      frameRateLabel = Number($frameRate).toFixed(1) + ' FPS'
      lastFrameUpdate = performance.now()
    }
  }
  $: frameRateColor = $avgFrameRate > 40 ? 'good' : ($avgFrameRate > 20 ? 'ok' : 'bad')

  const fxColor = 'good'
  let fxLabel = ''
  $: {
    const rate = $exchangeRates[$localCurrency]
    if (rate && rate.last)
    fxLabel = formatCurrency($localCurrency, rate.last)
  }

	const debounce = v => {
		clearTimeout(timer);
		timer = setTimeout(() => {
			val = v;
		}, 750);
	}

  let mousePosition = { x: 0, y: 0 }

  function onClick (e) {
    mousePosition = {
      x: e.clientX,
      y: e.clientY
    }
    const position = {
      x: e.clientX,
      y: window.innerHeight - e.clientY
    }
    if (txController) txController.mouseClick(position)
  }

  function pointerMove (e) {
    if (!txController.selectionLocked) {
      mousePosition = {
        x: e.clientX,
        y: e.clientY
      }
      const position = {
        x: e.clientX,
        y: window.innerHeight - e.clientY
      }
      if (txController) txController.mouseMove(position)
    }
  }

  function pointerLeave (e) {
    const position = {
      x: null,
      y: null
    }
    if (txController) txController.mouseMove(position)
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

  .mempool-height {
    position: absolute;
    bottom: calc(25% + 10px);
    left: 0;
    right: 0;
    margin: auto;
    padding: 0 .5rem;
    transition: bottom 1000ms;

    .mempool-count {
      position: absolute;
      bottom: .5em;
      left: 0.5rem;
      font-size: 0.9rem;
      color: var(--palette-x);

      // &::before {
      //   content: '';
      //   position: absolute;
      //   left: 0;
      //   top: 0;
      //   right: 0;
      //   bottom: 0;
      //   background: var(--palette-b);
      //   opacity: 0.5;
      // }
    }

    .height-bar {
      width: 100%;
      height: 1px;
      border-bottom: dashed 2px var(--palette-x);
      opacity: 0.75;
    }
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

      .stat-counter, .fx-ticker {
        margin-top: 5px;
        white-space: nowrap;

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
      // width: 75vw;
      // max-width: 40vh;
      margin: auto;

      .block-area {
        padding-top: 100%;
      }

      .guide-area {
        background: #00FF00;
        opacity: 25%;
        position: absolute;
        left: 0;
        right: 0;
        top: 0;
        bottom: 0;
      }
    }
  }

  .guide-overlay {
    position: absolute;
    left: 0;
    top: 0;
    right: 0;
    bottom: 0;
    width: 100%;
    height: 100%;

    pointer-events: none;

    .guide {
      position: absolute;
      background: #00FF00;
    }

    .v-half {
      top: 0;
      bottom: 0;
      left: calc(50% - 1px);
      width: 1px;
      margin: auto;
    }

    .h-half {
      top: calc(50% - 1px);
      left: 0;
      right: 0;
      height: 1px;
      margin: auto;
    }

    .mempool-height {
      bottom: 25%;
      left: 0;
      right: 0;
      height: 1px;
      margin: auto;
    }
  }
</style>

<svelte:window on:resize={resize} on:load={resize} on:click={pointerLeave} />
<!-- <svelte:window on:resize={resize} on:click={pointerMove} /> -->

<div class="tx-area" class:light-mode={!$settings.darkMode}>
  <div class="canvas-wrapper" on:pointerleave={pointerLeave} on:pointermove={pointerMove} on:click={onClick}>
    <TxRender controller={txController} />

    <div class="mempool-height" style="bottom: calc({$mempoolScreenHeight + 20}px)">
      <div class="height-bar" />
      <span class="mempool-count">Mempool: { integerFormat.format($mempoolCount) } unconfirmed</span>
    </div>

    <div class="block-area-wrapper">
      <div class="spacer"></div>
      <div class="block-area-outer" style="width: {$blockAreaSize}px; height: {$blockAreaSize}px">
        <div class="block-area">
          <BlockInfo block={$currentBlock} visible={$blockVisible} on:hideBlock={hideBlock} />
        </div>
        {#if config.dev && config.debug && $devSettings.guides }
          <div class="guide-area" />
        {/if}
      </div>
      <div class="spacer"></div>
      <div class="spacer"></div>
    </div>
  </div>

  {#if $selectedTx }
    <TxInfo tx={$selectedTx} position={mousePosition} />
  {/if}

  <div class="top-bar">
    <div class="status">
      <div class="row">
        {#if $settings.showFX && fxLabel }
          <span class="fx-ticker {fxColor}">{ fxLabel }</span>
        {/if}
      </div>
      <div class="row">
        {#if $settings.showNetworkStatus }
          <div class="status-light {connectionColor}" title={connectionTitle}></div>
        {/if}
        {#if $settings.showFPS }
          <span class="stat-counter {frameRateColor}">{ frameRateLabel }</span>
        {/if}
      </div>
    </div>
    <div class="spacer" />
    {#if $settings.showMessages }
      <Alerts />
    {/if}
  </div>

  <Sidebar />

  <AboutOverlay />
  {#if config.donationsEnabled }
    <DonationOverlay />
    {#if $showSupporters}
      <SupportersOverlay />
    {/if}
  {/if}

  {#if config.dev && config.debug && $devSettings.guides }
    <div class="guide-overlay">
      <div class="guide v-half" />
      <div class="guide h-half" />
      <div class="guide mempool-height" />
      <div class="area block-area" />
    </div>
  {/if}
</div>
