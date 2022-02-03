<script>
import SearchIcon from '../assets/icon/cil-search.svg'
import { highlight } from '../stores.js'

let query

$: {
  $highlight = [{
    id: query
  }]
}
</script>

<style type="text/scss">
  .search {
    .search-input {
      color: var(--palette-a);
      border: solid 3px var(--grey);
      margin: 0;
      width: 100%;

      &:active {
        border-color: var(--palette-good);
      }
    }
  }
</style>

<div class="search tab-content">
  <div class="input-wrapper">
    <input class="search-input" type="text" bind:value={query} placeholder="Enter a txid...">
  </div>
</div>
