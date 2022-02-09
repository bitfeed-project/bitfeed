<script>
import { tick } from 'svelte'
import { fly } from 'svelte/transition'

export let open = false
export let tooltip = null
let entered = false

let contentElement
let contentSlotElement

export async function updateContentHeight (isOpen) {
  if (contentElement && contentSlotElement) {
    if (isOpen) {
      contentElement.style.height = `${contentSlotElement.clientHeight}px`
    } else if (contentElement) {
      contentElement.style.height = null
    }
  }
}

$: updateContentHeight(open)

$: {
  if (open) setTimeout(afterEnter, 400)
  else beforeExit()
}

function afterEnter () {
  entered = true
}

function beforeExit () {
  entered = false
}

</script>

<style type="text/scss">
  .sidebar-tab {
    display: block;
    position: relative;
    margin-bottom: 5px;

    background: var(--palette-c);
    color: var(--palette-x);

    transform: translateX(0);

    transition: transform 300ms;

    .tab-button {
      position: absolute;
      right: calc(100% - 1px);

      display: block;
      padding: 5px;
      margin: 0;
      outline: none;
      background: none;
      border: none;
      border-radius: 0;
      border-bottom-left-radius: 5px;
      border-top-left-radius: 5px;

      background: var(--palette-c);
      color: var(--palette-x);
      font-size: 1.5rem;

      cursor: pointer;

      &:hover {
        background: var(--palette-d);
      }

      &::-moz-focus-inner {
        border: 0;
        padding: 0;
      }
    }

    .sidebar-content {
      height: calc(1.5rem + 10px);
      overflow: hidden;
      transition: height 300ms;
    }

    &.open {
      transform: translateX(-100%);

      &.active {
        .sidebar-content {
          overflow: visible;
        }
      }
    }
  }

  .sidebar-content :global(.tab-content) {
    padding: .5em;
    font-size: 0.8rem;

    :global(.square) {
      display: block;
      padding: 0;
      background: var(--bold-a);
    }

    :global(h3) {
      font-size: 1rem;
      font-weight: normal;
      margin: 0 0 .5rem;
      text-align: center;
    }
  }
</style>

<div
  class="sidebar-tab"
  class:open={open}
  class:active={entered}
  transition:fly={{ x: 30, duration: 1000 }}
>
  <button class="tab-button" on:click title={tooltip}>
    <slot name="tab">
      ??
    </slot>
  </button>

  <div class="sidebar-content" bind:this={contentElement}>
    <div class="inner-content" bind:this={contentSlotElement}>
      <slot name="content" />
    </div>
  </div>
</div>
