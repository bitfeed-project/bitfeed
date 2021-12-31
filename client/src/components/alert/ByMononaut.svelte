<script>
import Mononaut from '../Mononaut.svelte'
</script>

<div class="alert-content by-mononaut">
  <h3>Bitfeed</h3>
  <p class="by">by mononaut</p>
  <div class="monkey-avatar">
    <Mononaut />
  </div>
</div>

<style type="text/scss">
.by-mononaut {
  display: flex;
  flex-direction: row;
  justify-content: space-around;
  align-items: center;

  h3 {
    text-align: center;
    flex-grow: 1;
  }

  .by {
    margin-left: 10px;
  }

  .monkey-avatar {
    width: 3em;
    margin-left: 10px;
  }

  @media screen and (max-width: 480px) {
    .by {
      margin-left: 5px;
    }
  }
}

</style>
