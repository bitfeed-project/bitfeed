<script>
export let active
export let left
export let right

</script>

<div class="pill" class:active={active} on:click>
  <span class="side left" class:selected={!active}>{ left }</span>
  <span class="side right" class:selected={active}>{ right }</span>
</div>

<style type="text/scss">
.pill {
  display: inline-block;
  cursor: pointer;
  display: flex;
  flex-direction: row;
  width: 100%;
  border-radius: .5em;
  overflow: hidden;

  .side {
    width: 100%;
    flex-shrink: 1;
    flex-grow: 1;
    padding: .5em 1em;
    background: var(--palette-e);

    &.selected {
      background: var(--palette-good);
      color: var(--palette-a);
    }
  }
}
</style>
