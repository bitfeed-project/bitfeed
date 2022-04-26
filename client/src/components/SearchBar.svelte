<script>
import { tick } from 'svelte'
import { fade } from 'svelte/transition'
import { flip } from 'svelte/animate'
import Icon from './Icon.svelte'
import SearchIcon from '../assets/icon/cil-search.svg'
import CrossIcon from '../assets/icon/cil-x-circle.svg'
import AddressIcon from '../assets/icon/cil-wallet.svg'
import TxIcon from '../assets/icon/cil-arrow-circle-right.svg'
import BlockIcon from '../assets/icon/grid-icon.svg'
import { fly } from 'svelte/transition'
import { matchQuery, searchTx, searchBlockHeight, searchBlockHash } from '../utils/search.js'
import { selectedTx, detailTx, overlay, loading } from '../stores.js'

const queryIcons = {
  txid: TxIcon,
  input: TxIcon,
  output: TxIcon,
  // address: AddressIcon,
  blockhash: BlockIcon,
  blockheight: BlockIcon,
}

let query
let matchedQuery
let errorMessage

$: {
  if (query) {
    matchedQuery = matchQuery(query)
  } else {
    matchedQuery = null
  }
  errorMessage = null
}

function clearInput () {
  query = null
}

function handleSearchError (err) {
  switch (err) {
    case '404':
      if (matchedQuery && matchedQuery.label) {
        errorMessage = `${matchedQuery.label} not found`
      }
      break;
    default:
      errorMessage = 'server error'
  }
}

async function searchSubmit (e) {
  e.preventDefault()

  if (matchedQuery && matchedQuery.query !== 'address') {
    loading.increment()
    let searchErr
    switch(matchedQuery.query) {
      case 'txid':
        searchErr = await searchTx(matchedQuery.txid)
        break;

      case 'input':
        searchErr = await searchTx(matchedQuery.txid, matchedQuery.input, null)
        break;

      case 'output':
        searchErr = await searchTx(matchedQuery.txid, null, matchedQuery.output)
        break;

      case 'blockheight':
        searchErr = await searchBlockHeight(matchedQuery.height)
        break;

      case 'blockhash':
        searchErr = await searchBlockHash(matchedQuery.hash)
        break;
    }
    if (searchErr == null) errorMessage = null
    else handleSearchError(searchErr)
    loading.decrement()
  } else {
    errorMessage = 'enter a transaction id, block hash or block height'
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

  .clear-button {
    position: absolute;
    right: 0;
    bottom: .4em;
    margin: 0;
    color: var(--palette-bad);
    font-size: 1.2em;
    cursor: pointer;
    opacity: 1;
    transition: opacity 300ms;

    &.disabled {
      opacity: 0;
    }
  }

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

    .error-msg {
      position: absolute;
      left: 0;
      top: 100%;
      margin: 0;
      font-size: 0.9em;
      color: var(--palette-bad);
    }

    .input-icon.query-type {
      position: absolute;
      left: 0;
      bottom: .4em;
      margin: 0;
      color: var(--palette-x);
      font-size: 1.2em;
    }
  }

  .search-input:active, .search-input:focus {
    & ~ .underline.active {
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
    padding-left: 1.5em;
    padding-right: 1.5em;

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
    <div class="clear-button" class:disabled={query == null || query === ''} on:click={clearInput} title="Clear">
      <Icon icon={CrossIcon}/>
    </div>
    <div class="underline" />
    <div class="underline active" />
    <button type="submit" class="search-submit" />
    {#if matchedQuery && matchedQuery.query && queryIcons[matchedQuery.query]}
      <div class="input-icon query-type" transition:fade={{ duration: 300 }} title={matchedQuery.label}>
        <Icon icon={queryIcons[matchedQuery.query]} />
      </div>
    {/if}
    {#if errorMessage }
      <p class="error-msg" transition:fade={{ duration: 300 }}>{ errorMessage }</p>
    {/if}
  </form>
  <div class="input-icon search icon-button" on:click={searchSubmit} title="Search">
    <Icon icon={SearchIcon}/>
  </div>
</div>
