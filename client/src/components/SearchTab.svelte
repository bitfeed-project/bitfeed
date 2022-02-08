<script>
import SearchIcon from '../assets/icon/cil-search.svg'
import { matchQuery } from '../utils/search.js'
import { highlight } from '../stores.js'

let query

$: {
  if (query) {
    const matchedQuery = matchQuery(query.trim())
    if (matchedQuery) {
      $highlight = [matchedQuery]
    } else $highlight = []
  } else $highlight = []
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
    <input class="search-input" type="text" bind:value={query} placeholder="Enter an address or txid...">
  </div>
</div>
