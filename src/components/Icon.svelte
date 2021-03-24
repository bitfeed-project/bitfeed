<script>
export let icon
export let inline = false
export let color = "white"
</script>

<style type="text/scss">
.svg-icon {
  display: flex;
  justify-content: center;
  align-items: center;

  :global(svg) {
    height: 0.9em;
  }

  &.inline {
    display: inline;
    :global(svg) {
      margin-bottom: -4%;
    }
  }
}
</style>

<span class="svg-icon" class:inline style="fill: {color}; stroke: {color}; color: {color}">
  {@html icon }
</span>
