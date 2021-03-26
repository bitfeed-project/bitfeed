<script>
import { tick } from 'svelte'
export let open = false
let contentElement
let contentSlotElement

async function updateContentHeight (isOpen) {
  if (contentElement && contentSlotElement) {
    if (isOpen) {
      contentElement.style.height = `${contentSlotElement.clientHeight}px`
    } else if (contentElement) {
      contentElement.style.height = null
    }
  }
}

$: updateContentHeight(open)

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
      right: 100%;

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
    }
  }
</style>

<div class="sidebar-tab" class:open={open}>
  <button class="tab-button" on:click>
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
