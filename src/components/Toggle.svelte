<script>
export let active

</script>

<div class="toggle" class:active={active} on:click>
  <div class="track">
    <div class="handle" />
  </div>
</div>

<style type="text/scss">
.toggle {
  display: inline-block;
  cursor: pointer;

  .track {
    position: relative;
    width: 2em;
    height: 1em;
    border-radius: .5em;
    background: var(--palette-e);

    transition: background 200ms;

    .handle {
      position: absolute;
      left: 0;
      top: 0;
      bottom: 0;
      width: 1em;
      height: 1em;
      border-radius: 50%;
      background: white;

      transition: left 200ms;
    }
  }

  &.active {
    .track {
      background: var(--palette-good);

      .handle {
        left: 1em;
      }
    }
  }
}
</style>
