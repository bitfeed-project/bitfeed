<script>
export let icon
export let inline = false
export let color = "white"
</script>

<style type="text/scss">
.svg-icon {
  line-height: 1em;
  :global(svg) {
    height: 1em;
    margin-bottom: -16%
  }

  &.inline {
    display: inline;
    :global(svg) {
      margin-bottom: -4%;
    }
  }
}
</style>

{#if inline}
<span class="svg-icon inline" style="fill: {color}; stroke: {color}; color: {color}">
  {@html icon }
</span>
{:else}
<div class="svg-icon" style="fill: {color}; stroke: {color}; color: {color}">
  {@html icon }
</div>
{/if}
