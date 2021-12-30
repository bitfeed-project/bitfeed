<script>
import Icon from '../Icon.svelte'

export let active
export let title
export let optional
export let description
export let min // in BTC

function formatAmount (btc) {
  if (btc >= 0.01) return `₿ ${btc}`
  else return `${Math.round(btc * 100000000).toLocaleString()} sats`
}
</script>

<div class="tier-card" class:active on:click>
  <h3 class="title">{ title }</h3>
  <p class="desc">
    { description }
  </p>
  <p class="min">
    {#if min && !optional}
      ≥ { formatAmount(min) }
    {:else}
      &nbsp;
    {/if}
  </p>
</div>

<style type="text/scss">
  .tier-card {
    display: flex;
    flex-direction: column;
    align-items: stretch;
    cursor: pointer;
    margin: 20px;
    min-width: 12em;
    width: 12em;
    max-width: 15em;
    flex-grow: 1;
    flex-shrink: 1;
    background: var(--palette-d);
    border-radius: 10px;
    overflow: hidden;
    border: solid 5px var(--palette-x);

    .title, .min {
      margin: 0;
      padding: 10px;
      background: var(--palette-e);
      font-weight: 600;
    }

    .desc {
      flex-grow: 1;
      margin: 20px 5px;
    }

    &.active {
      border: solid 5px var(--bold-a);
      box-shadow: 0px 0px 30px -10px var(--bold-a);

      .title, .min {
        color: var(--bold-a);
      }
      .title {
        text-shadow: 0px 0px 10px var(--bold-a);
      }
    }
    &:hover {
      box-shadow: 0px 0px 30px -10px var(--bold-a);
      .title {
        text-shadow: 0px 0px 10px var(--bold-a);
      }
    }
  }
</style>
