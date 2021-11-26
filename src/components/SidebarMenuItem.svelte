<script>
import Toggle from '../components/Toggle.svelte'
import Pill from '../components/Pill.svelte'

export let active = false
export let type = 'toggle'
export let label = ''
export let falseLabel
export let trueLabel
</script>

<style type="text/scss">
  .sidebar-menu-item {
    display: flex;
    flex-direction: row;
    justify-content: space-between;
    align-items: baseline;
    text-align: left;
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

    .label {
      margin-right: 0.5em;
    }
  }
</style>

<div class="sidebar-menu-item" class:active={active} on:click>
  {#if type === 'pill'}
    <span class="label">{ label }</span>
    <Pill active={active} left={falseLabel} right={trueLabel} />
  {:else}
    <span class="label">{ label }</span>
    <Toggle active={active} />
  {/if}
</div>
