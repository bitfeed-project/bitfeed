<script>
export let open = false
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
    }

    .sidebar-content {
      max-height: calc(1.5rem + 10px);
      overflow: hidden;
      transition: max-height 300ms;
    }

    &.open {
      transform: translateX(-100%);

      .sidebar-content {
        max-height: 200px;
      }
    }
  }
</style>

<div class="sidebar-tab" class:open={open}>
  <button class="tab-button" on:click>
    <slot name="tab">
      ??
    </slot>
  </button>

  <div class="sidebar-content">
    <slot name="content" />
  </div>
</div>
