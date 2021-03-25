<script>
export let active = false
export let label = ''
</script>

<style type="text/scss">
  .sidebar-menu-item {
    text-align: right;
    padding: 5px 10px;
    background: var(--palette-c);
    color: var(--palette-x);
    font-size: 0.8em;
    cursor: pointer;
    white-space: nowrap;

    &:nth-child(odd) {
      background: var(--palette-d);
    }

    &:hover {
      text-shadow: 0 0 1px var(--palette-x);
    }

    &.active {
      text-decoration: underline;
      text-decoration-color: var(--bold-a);
    }
  }
</style>

<div class="sidebar-menu-item" class:active={active} on:click>
  { label }
</div>
