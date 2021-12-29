<script>
export let active
export let left
export let right
export let leftDisabled = false
export let rightDisabled = false

</script>

<div class="pill" class:active={active} on:click>
  {#if !leftDisabled}
    <span class="side left" class:selected={!active}><slot name="left">{ left }</slot></span>
  {/if}
  {#if !rightDisabled}
    <span class="side right" class:selected={active}><slot name="right">{ right }</slot></span>
  {/if}
</div>

<style type="text/scss">
.pill {
  display: inline-block;
  cursor: pointer;
  display: flex;
  flex-direction: row;
  justify-content: center;
  width: 100%;
  overflow: hidden;

  .side {
    width: 100%;
    max-width: 400px;
    flex-shrink: 1;
    flex-grow: 1;
    padding: .5em 1em;
    background: var(--palette-e);

    &:first-child {
      border-top-left-radius: .5em;
      border-bottom-left-radius: .5em;
    }
    &:last-child {
      border-top-right-radius: .5em;
      border-bottom-right-radius: .5em;
    }

    &.selected {
      background: var(--palette-good);
      color: var(--palette-a);
    }
  }
}
</style>
