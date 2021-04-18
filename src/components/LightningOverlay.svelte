<script>
import Overlay from '../components/Overlay.svelte'

</script>

<style type="text/scss">
  .info {
    p {
      text-align: justify;
    }

    i {
      font-style: italic;
    }
  }
</style>

<Overlay name="lightning">
  <section class="info">
    <h2>Donate with Lightning</h2>
    <p>
      Enter the amount you would like to donate, then click the button to generate a payment request:
    </p>

  </section>
</Overlay>
