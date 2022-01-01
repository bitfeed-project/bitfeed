<script>
export let img
export let name
</script>

<div class="alert-content sponsored-by">
  <p class="msg">Sponsored by</p>
  <h3>{ name }</h3>
  {#if img}
    <img src={img} alt="name" class="logo">
  {/if}
</div>

<style type="text/scss">
.sponsored-by {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
  color: var(--palette-x);

  h3 {
    text-align: center;
    margin: 0 10px;
    flex-grow: 1;
    flex-shrink: 1;
  }

  .msg {
    white-space: nowrap;
  }

  .logo {
    height: 3em;
  }
}

</style>
