<script>
export let tx
export let position

let clampedX
$: clampedX = Math.min(position.x, window.innerWidth - 250)

function formatBTC (sats) {
  return `${(sats/100000000).toFixed(8)} BTC`
}
</script>

<style type="text/scss">
  .tx-info {
    position: fixed;
    z-index: 50;
    width: 240px;
    display: block;
    transform: translate(-1rem, -120%);
    pointer-events: none;

    background: var(--palette-c);
    color: var(--palette-x);
    padding: .5rem;

    font-size: 0.8rem;
    text-align: left;

    .field {
      margin: 0;
    }

    .hash {
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
  }
</style>

<div class="tx-info" style="left: {clampedX}px; top: {position.y}px">
  <p class="field hash">
    TxID: { tx.id }
  </p>
  {#if tx.inputs }<p class="field inputs">{ tx.inputs.length } inputs</p>{/if}
  {#if tx.outputs }<p class="field outputs">{ tx.outputs.length } outputs</p>{/if}
  <p class="field value">
    Total value: { formatBTC(tx.value) }
  </p>
</div>
