<script>
  import { fly } from 'svelte/transition'
  import { linear } from 'svelte/easing'

  export let block

  function formatTime (time) {
    return (new Date(time)).toLocaleTimeString()
  }

  function formatBTC (sats) {
    return `${(sats/100000000).toPrecision(8)} BTC`
  }

  function formatBytes (bytes) {
    if (bytes) {
      return `${bytes.toLocaleString()} bytes`
    } else return `unknown size`
  }
</script>

<style type="text/scss">
  .block-info {
    position: absolute;
    bottom: 100%;
    left: 0;
    right: 0;

    color: var(--palette-x);
    font-size: 12px;

    .data-row {
      display: flex;
      flex-direction: row;
      flex-wrap: wrap;
      justify-content: space-between;
    }

    .data-field {
      margin: 1px;
    }
  }
</style>

{#if block != null }
<div class="block-info" out:fly="{{ y: -50, duration: 2000, easing: linear }}" in:fly="{{ y: 50, duration: 1000, easing: linear }}">
    <!-- <span class="data-field">Hash: { block.id }</span> -->
    <div class="data-row">
      <span class="data-field">Block mined at { formatTime(block.time) }</span>
      <span class="data-field">{ formatBTC(block.value) }</span>
    </div>
    <div class="data-row">
      <span class="data-field">{ formatBytes(block.bytes) }</span>
      <span class="data-field">{ block.txnCount } transactions</span>
    </div>
</div>
{/if}
