<script>
import { tick } from 'svelte'
import Toggle from './util/Toggle.svelte'
import Pill from './util/Pill.svelte'
import Select from 'svelte-select'
import { createEventDispatcher } from 'svelte'
import { freezeResize } from '../stores.js'
const dispatch = createEventDispatcher()

export let value = false
export let type = 'toggle'
export let label = ''
export let falseLabel
export let trueLabel
export let options
let selectedOption

$: {
  if (options && value) {
    selectedOption = options.find(option => option.value === value)
  }
}

function filterSelectItems (label, filterText, option) {
  return [label, ...option.tags].join(' | ').toLowerCase().includes(filterText.toLowerCase())
}

function onSelect (e) {
  selectedOption = e.detail
  dispatch('input', selectedOption.value )
  if (document.activeElement) document.activeElement.blur()
}

let freezeTimeout
function focusIn(e) {
  if (freezeTimeout) clearTimeout(freezeTimeout)
  $freezeResize = true
}
async function focusOut(e) {
  freezeTimeout = setTimeout(() => {
    $freezeResize = false
  }, 500)
}
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

    .select {
      width: 240px;
      flex-shrink: 0;
      color: var(--palette-a);
      --inputColor: var(--palette-a);
      --itemColor: var(--palette-a);
      --itemHoverColor: var(--palette-a);
      --borderFocusColor: var(--palette-good);

      :global(.selectContainer) {
        border-width: 3px;
      }
    }
  }
</style>

<div class="sidebar-menu-item" class:active={value} on:click>
  {#if type === 'pill'}
    <span class="label">{ label }</span>
    <Pill active={value} left={falseLabel} right={trueLabel} />
  {:else if type === 'dropdown'}
    <div class="select" on:focusin={focusIn} on:focusOut={focusOut}>
      <Select items={ options } value={selectedOption} isSearchable={true} isClearable={false} itemFilter={filterSelectItems} placeholder={label} on:select={onSelect} showIndicator={true} />
    </div>
  {:else}
    <span class="label">{ label }</span>
    <Toggle active={value} />
  {/if}
</div>
