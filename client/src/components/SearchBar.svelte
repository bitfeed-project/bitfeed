<script>
import { tick } from 'svelte'
import { fade } from 'svelte/transition'
import { flip } from 'svelte/animate'
import Icon from './Icon.svelte'
import SearchIcon from '../assets/icon/cil-search.svg'
import CrossIcon from '../assets/icon/cil-x.svg'
import AddressIcon from '../assets/icon/cil-wallet.svg'
import TxIcon from '../assets/icon/cil-arrow-circle-right.svg'
import { fly } from 'svelte/transition'
import { matchQuery, searchTx, searchBlock } from '../utils/search.js'
import { selectedTx, detailTx, overlay } from '../stores.js'

let query
let matchedQuery

$: {
  if (query) {
    matchedQuery = matchQuery(query)
  } else {
    matchedQuery = null
  }
}

async function searchSubmit (e) {
  e.preventDefault()

  if (matchedQuery) {
    switch(matchedQuery.query) {
      case 'txid':
        searchTx(matchedQuery.txid)
        break;

      case 'input':
        searchTx(matchedQuery.txid, matchedQuery.input, null)
        break;

      case 'output':
        searchTx(matchedQuery.txid, null, matchedQuery.output)
        break;
    }
  }

  return false
}

</script>

<style type="text/scss">
.input-wrapper {
  display: flex;
  flex-direction: row;
  align-items: baseline;
  --input-color: var(--palette-x);
  width: 100%;
  max-width: 600px;
  margin: 0 1em;

  .input-icon {
    font-size: 24px;
    margin: 0 10px;
    transition: opacity 300ms, color 300ms, background 300ms;
    color: var(--input-color);

    &.search {
      color: var(--bold-a);
    }
    &.icon-button {
      cursor: pointer;
    }

    &.hidden {
      opacity: 0;
    }

    &.icon-button {
      background: var(--palette-d);
      padding: 6px;
      border-radius: 5px;
      &:hover {
        background: var(--palette-e);
      }

      &.disabled {
        color: var(--palette-e);
        background: none;
      }
    }
  }

  .search-form {
    position: relative;
    width: 100%;
    margin: 0;
    padding: 0;

    .search-submit {
      display: none;
    }

    .underline {
      position: absolute;
      left: 0;
      right: 0;
      bottom: 0;
      height: 2px;
      background: var(--palette-x);
      opacity: 0.5;

      &.active {
        width: 0%;
        opacity: 1;
        transition: width 300ms;
      }
    }
  }

  &:hover, &:active, &:focus {
    .underline.active {
      width: 100%;
    }
  }

  .search-input {
    background: none;
    border: none;
    outline: none;
    margin: 0;
    color: var(--input-color);
    width: 100%;

    &.disabled {
      color: var(--palette-e);
      user-select: none;
      pointer-events: none;
    }
  }
}
</style>

<div class="input-wrapper" transition:fly={{ y: -25 }}>
  <form class="search-form" action="" on:submit={searchSubmit}>
    <input class="search-input" type="text" bind:value={query} placeholder="Enter a txid">
    <div class="underline" />
    <div class="underline active" />
    <button type="submit" class="search-submit" />
  </form>
  <div class="input-icon search icon-button" on:click={searchSubmit} title="Search">
    <Icon icon={SearchIcon}/>
  </div>
</div>
