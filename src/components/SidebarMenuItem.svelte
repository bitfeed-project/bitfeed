<script>
import Toggle from '../components/Toggle.svelte'

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

    &:hover {
      background: var(--palette-d);
      text-shadow: 0 0 1px var(--palette-x);
    }
  }
</style>

<div class="sidebar-menu-item" class:active={active} on:click>
  { label }
  <Toggle active={active} />
</div>
