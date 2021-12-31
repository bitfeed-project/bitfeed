<script>
export let msg
export let shortmsg = null
export let img
</script>

<div class="alert-content generic-alert">
  <p class="msg">
    {@html msg }
  </p>
  <p class="shortmsg">
    {@html shortmsg || msg }
  </p>
  {#if img}
    <img src={img} alt="">
  {/if}
</div>

<style>
.generic-alert {
  display: flex;
  flex-direction: row;
  justify-content: space-around;
  align-items: center;
}
.msg, .shortmsg {
  margin: 0;
  font-size: .9em;
  width: 100%;
  text-align: center;
  max-height: 100%;
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
}
.shortmsg {
  display: none;
}
img {
  height: 2.8em;
}

@media screen and (max-width: 480px) {
  .shortmsg {
    display: inline;
  }
  .msg {
    display: none;
  }
}
</style>
