<script>
  import { onMount } from 'svelte'
  import WorldMap from './WorldMap.svelte'
  import TxSprite from './TxSprite.svelte'
  import TxRender from './TxRender.svelte'
  import { txPool, txList, darkMode } from '../stores.js'
  import { bounceIn } from 'svelte/easing'
  import { tweened } from 'svelte/motion'

  function plip(node, params) {
		/*const existingTransform = getComputedStyle(node).transform.replace('none', '');*/

		return {
			delay: params.delay || 0,
			duration: params.duration || 1000,
			easing: params.easing || bounceIn,
			css: (t, u) => `transform: scale(${t})`
		};
	}

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

  const cleanInterval = setInterval(cleanTxs, 500)

  onMount(() => {
    //fakeTxStream()
    txPool.add({
      id: 'test',
      coords: {
        lat: 10.033766870069249,
        lng: -84.04541015625
      },
      status: 'mempool'
    })
    txPool.add({
      id: 'test2',
      coords: {
        lat: 76.56284986632164,
        lng: 16.6552734375
      },
      status: 'mempool'
    })
    txPool.add({
      id: 'center',
      coords: {
        lat: 0,
        lng: 0
      },
      status: 'mempool'
    })
    /*txPool.add({
      id: 'north',
      coords: {
        lat: 90,
        lng: 0
      },
      status: 'mempool'
    })
    txPool.add({
      id: 'east',
      coords: {
        lat: 0,
        lng: 180
      },
      status: 'mempool'
    })
    txPool.add({
      id: 'south',
      coords: {
        lat: -90,
        lng: 0
      },
      status: 'mempool'
    })
    txPool.add({
      id: 'west',
      coords: {
        lat: 0,
        lng: -180
      },
      status: 'mempool'
    })*/
    txPool.add({
      id: 'madagascar',
      coords: {
        lat: -12.082295837363578,
        lng: 49.273681640625
      },
      status: 'mempool'
    })

    running = true
  })

  function addTx () {
    txPool.add({
      id: idCounter++,
      coords: {
        lat: (Math.random()*180) - 90,
        lng: (Math.random()*360) - 180
      },
      status: 'mempool'
    })
  }

  function cleanTxs () {
    const newPool = $txPool
    const oldList = $txList
    const cutoff = Date.now() - 1000
    for (var i = 0; i < oldList.length; i++) {
      if (newPool[oldList[i].id].status === 'mined' && newPool[oldList[i].id].last < cutoff) {
        delete newPool[oldList[i].id]
      }
    }
    txPool.set(newPool)
  }

  function newBlock () {
    const newPool = $txPool
    const oldList = $txList
    const now = Date.now()
    let blockSize = 1250 + (Math.random() * 1250)
    for (let i = 0, m = 0; i < oldList.length && m < blockSize; i++) {
      if (newPool[oldList[i].id].status !== 'mined') {
        newPool[oldList[i].id].status = 'mined'
        newPool[oldList[i].id].last = now
        m++
      }
    }
    txPool.set(newPool)
  }

  function mapClick (e) {
    txPool.add({
      id: idCounter++,
      p: e.detail,
      status: 'mempool'
    })
  }

  function toggleDark () {
    $darkMode = !$darkMode
  }
</script>

<style type="text/scss">
  .tx-map {
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

  .map-wrapper {
    position: relative;
    width: 100%;
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

<div class="tx-map" class:light-mode={!$darkMode}>
  <div class="map-wrapper">
    <WorldMap on:mapclick={mapClick} />
    <TxRender txs={$txList} />
    <!-- <svg viewBox="0 6 960 480" class="tx-layer">
      <g>
        {#each $txList as tx (tx.id)}
          <TxSprite {tx} />
        {/each}
      </g>
    </svg> -->
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
