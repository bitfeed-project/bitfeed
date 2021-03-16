<script>
  import { onMount } from 'svelte'
  import TxRender from './TxRender.svelte'
  import { txPool, txList, darkMode } from '../stores.js'

  let idCounter = 0
  let running = false
  $: {
    if (running) fakeTxStream()
  }
  $: mempoolSize = $txList.filter(tx => {
    return tx.status === 'mempool'
  }).length

  let lastFrame = Date.now()
  let nextBlock = Date.now()
  function fakeTxStream () {
    const now = Date.now()
    let elapsed = now - lastFrame
    lastFrame = now
    let txDice = Math.random() * 250
    if (txDice < elapsed) addTx()
    //for (let i = 0; i < 10; i++) addTx()

    if (nextBlock < now) {
      newBlock()
      nextBlock = now + (Math.random() * 1200000)
    }
    if (running) {
      requestAnimationFrame(fakeTxStream)
    }
  }

  const cleanInterval = setInterval(rotateTxs, 200)

  onMount(() => {
    //fakeTxStream()
    txPool.add({
      id: 'test',
      amount: 0.01
    })
    txPool.add({
      id: 'test2',
      amount: 0.1
    })
    txPool.add({
      id: 'center',
      amount: 1.0
    })
  })

  function addTx () {
    txPool.add({
      id: idCounter++,
      amount: Math.pow((Math.random()*2), 2)
    })
  }

  function rotateTxs () {
    txPool.rotateTxs()
  }

  function newBlock () {
    let blockSize = 1800 + (Math.random() * 2400)
    const txIds = Object.keys($txPool).filter(key => {
      return $txPool[key].status === 'mempool' || $txPool[key].status === 'entry'
    }).slice(0, blockSize)
    txPool.mineTxs(txIds)
  }

  function txOnClick (e) {
    txPool.add({
      id: idCounter++,
      coords: e.detail
    })
  }

  function toggleDark () {
    $darkMode = !$darkMode
  }
</script>

<style type="text/scss">
  .tx-area {
    position: relative;
    width: 100vw;
    height: 100vh;
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
    bottom: 20px;
    left: 0;
    right: 0;
  }
</style>

<div class="tx-area" class:light-mode={!$darkMode}>
  <div class="canvas-wrapper">
    <TxRender txs={$txList} on:makeTx={txOnClick} />
  </div>
  <p class="mempool-size-label">Mempool size: {mempoolSize}</p>
  <div class="sim-controls">
    <button on:click={() => running = !running}>{ running ? 'STOP' : 'GO'}</button>
    <button on:click={newBlock}>BLOCK</button>
    <button on:click={toggleDark}>{$darkMode ? 'LIGHT' : 'DARK' }</button>
  </div>
  <!-- {#each $txList as tx}
    <p>!!{tx.id} {tx.status}</p>
  {/each} -->
</div>
