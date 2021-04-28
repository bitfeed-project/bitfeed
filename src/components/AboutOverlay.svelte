<script>
import Overlay from '../components/Overlay.svelte'
import MempoolLegend from '../components/MempoolLegend.svelte'
import { settings } from '../stores.js'

function onClose () {
  localStorage.setItem('seen-welcome-msg', true)
}
</script>

<style type="text/scss">
  .about {
    p {
      text-align: justify;
    }

    .nobreak {
      white-space: nowrap;
    }

    .figure {
      border: solid .2rem var(--palette-d);
      background: var(--palette-d);
      border-radius: 5px;
      overflow: hidden;
      width: calc(360px + .4rem);
      max-width: 75vw;
      margin: auto;
    }

    .figure.block {
      img {
        width: 100%;
        vertical-align: middle;
      }
    }
  }
</style>

<Overlay name="about" on:close={onClose}>
  <section class="about">
    <h2>Welcome to Bitfeed!</h2>
    <p>
      On a typical day, the Bitcoin network confirms around 300,000 transactions by mining an average of <span class="nobreak">144 blocks</span>.
      Bitfeed attempts to visualise this flow of information.
    </p>
    <p>
      As new transactions are recieved by our nodes, they drop into the mempool to await confirmation.
    </p>
    <p>
      Squares representing transactions in the mempool are sized according to total output value,
      on a logarithmic scale (each additional unit of width represents a 10x increase in value).
    </p>
    <div class="figure mempool-figure">
      <MempoolLegend />
    </div>
    <p>
      Tap, click or mouse-over a square for transaction details.
    </p>
    <p>
      Every 10 minutes, on average, Bitcoin miners confirm transactions from the mempool by packaging them into blocks.
    </p>
    <div class="figure block">
      {#if $settings.darkMode }
        <img src="/img/block-dark.png" alt="" class="block-example">
      {:else}
        <img src="/img/block-light.png" alt="" class="block-example">
      {/if}
    </div>
    <p>
      Bitfeed illustrates this movement from the mempool into each newly discovered block,
      arranging confirmed transactions to show the total number and distribution of values.
    </p>
  </section>
</Overlay>
