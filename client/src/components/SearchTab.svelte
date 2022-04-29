<script>
import { tick } from 'svelte'
import { fade } from 'svelte/transition'
import { flip } from 'svelte/animate'
import Icon from './Icon.svelte'
import SearchIcon from '../assets/icon/cil-search.svg'
import PlusIcon from '../assets/icon/cil-plus.svg'
import CrossIcon from '../assets/icon/cil-x.svg'
import AddressIcon from '../assets/icon/cil-wallet.svg'
import TxIcon from '../assets/icon/cil-arrow-circle-right.svg'
import { matchQuery } from '../utils/search.js'
import { highlight, newHighlightQuery, highlightingFull, freezeResize } from '../stores.js'
import { hlToHex, highlightA, highlightB, highlightC, highlightD, highlightE } from '../utils/color.js'

const highlightColors = [highlightA, highlightB, highlightC, highlightD, highlightE]
const highlightHexColors = highlightColors.map(c => hlToHex(c))
const usedColors = [false, false, false, false, false]

const queryIcons = {
  txid: TxIcon,
  address: AddressIcon
}
const queryType = {
  txid: 'transaction',
  address: 'address'
}

export let tab

let query
let matchedQuery
let queryAddress
let queryColorIndex
let queryColor
let queryColorHex
let watchlist = []

init ()

setNextColor()

$: {
  if ($newHighlightQuery) {
    matchedQuery = matchQuery($newHighlightQuery)
    if (matchedQuery && (matchedQuery.query === 'blockhash' || matchedQuery.query === 'blockheight')) matchedQuery = null
    if (matchedQuery) {
      matchedQuery.colorIndex = queryColorIndex
      matchedQuery.color = highlightColors[queryColorIndex]
      matchedQuery.colorHex = highlightHexColors[queryColorIndex]
      add()
      query = null
    }
    $newHighlightQuery = null
  }
}
$: {
  $highlight = matchedQuery ? [ ...watchlist, matchedQuery ] : watchlist
}
$: {
  localStorage.setItem('highlight', JSON.stringify(watchlist))
}
$: {
  if (query) {
    matchedQuery = matchQuery(query.trim())
    if (matchedQuery && (matchedQuery.query === 'blockhash' || matchedQuery.query === 'blockheight')) matchedQuery = null
    if (matchedQuery) {
      matchedQuery.colorIndex = queryColorIndex
      matchedQuery.color = highlightColors[queryColorIndex]
      matchedQuery.colorHex = highlightHexColors[queryColorIndex]
    }
  } else matchedQuery = null
}
$: {
  $highlightingFull = watchlist.length >= 5
}

function init () {
  const val = localStorage.getItem('highlight')
  if (val != null) {
    try {
      watchlist = JSON.parse(val)
      watchlist.forEach(q => {
        if (q.colorIndex) {
          usedColors[q.colorIndex] = true
          q.color = highlightColors[q.colorIndex]
          q.colorHex = highlightHexColors[q.colorIndex]
        }
      })
      watchlist.forEach(q => {
        if (!q.colorIndex){
          const nextIndex = usedColors.findIndex(used => !used)
          usedColors[nextIndex] = true
          q.colorIndex = nextIndex
          q.color = highlightColors[nextIndex]
          q.colorHex = highlightHexColors[nextIndex]
        }
      })
    } catch (e) {
      console.log('failed to parse cached highlight queries')
    }
  }
}

function setNextColor () {
  const nextIndex = usedColors.findIndex(used => !used)
  if (nextIndex >= 0) {
    queryColorIndex = nextIndex
    queryColor = highlightColors[nextIndex]
    queryColorHex = highlightHexColors[nextIndex]
    usedColors[nextIndex] = true
  }
}
function clearUsedColor (colorIndex) {
  usedColors[colorIndex] = false
}

async function add () {
  if (matchedQuery && matchedQuery.query !== 'blockhash' && matchedQuery.query !== 'blockheight' && !$highlightingFull) {
    watchlist.push({
      ...matchedQuery
    })
    watchlist = watchlist
    query = null
    setNextColor()
    if (tab) {
      await tick()
      tab.updateContentHeight(true)
    }
  }
}

async function remove (index) {
  const wasFull = $highlightingFull
  const removed = watchlist.splice(index,1)
  if (removed.length) {
    clearUsedColor(removed[0].colorIndex)
    watchlist = watchlist
    if (tab) {
      await tick()
      tab.updateContentHeight(true)
    }
    if (wasFull) setNextColor()
  }
}

function searchSubmit (e) {
  e.preventDefault()
  if (document.activeElement) document.activeElement.blur()
  add()
  return false
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
  .search {
    width: 274px;

    .watched, .input-wrapper {
      width: 100%;
      display: flex;
      flex-direction: row;
      align-items: baseline;
      --input-color: var(--bold-a);

      .search-form {
        width: 100%;
        margin: 0;
        padding: 0;

        .search-submit {
          display: none;
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

      .query {
        width: 100%;
        flex-grow: 1;
        flex-shrink: 1;
        overflow: hidden;
        text-overflow: ellipsis;
      }

      .input-icon {
        font-size: 24px;
        margin: 7px;
        transition: opacity 300ms, color 300ms, background 300ms;
        color: var(--input-color);

        &.add-query {
          color: var(--light-good);
        }
        &.remove-query {
          color: var(--light-bad);
        }
        &.icon-button {
          cursor: pointer;
        }

        &.hidden {
          opacity: 0;
        }

        &.icon-button {
          background: var(--palette-d);
          padding: 3px;
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
    }

    .input-wrapper {
      border-bottom: solid 3px var(--input-color);

      &.full {
        border-color: var(--palette-e);
      }
    }
  }
</style>

<div class="search tab-content">
  <div class="input-wrapper" class:full={$highlightingFull} style="--input-color: {queryColorHex};">
    {#if !$highlightingFull }
      <form class="search-form" action="" on:submit={searchSubmit}>
        <input class="search-input" type="text" bind:value={query} placeholder="Enter an address or txid..." on:focusin={focusIn} on:focusOut={focusOut}>
        <button type="submit" class="search-submit" />
      </form>
    {:else}
      <input class="search-input disabled" type="text" placeholder="Watchlist is full">
    {/if}
    <div class="input-icon add-query icon-button" class:disabled={matchedQuery == null || $highlightingFull} on:click={add} title="Add to watchlist">
      <Icon icon={PlusIcon}/>
    </div>
  </div>
  <div class="watchlist">
    {#each watchlist as watched, index (watched.colorIndex)}
      <div
        class="watched"
				transition:fade={{ duration: 200 }}
				animate:flip={{ duration: 200 }}
      >
        <div class="input-icon query-type" style="color: {watched.colorHex};" title={queryType[watched.query]}>
          <Icon icon={queryIcons[watched.query]} />
        </div>
        <span class="query" style="color: {watched.colorHex};">{ watched.value }</span>
        <div class="input-icon remove-query icon-button" on:click={() => remove(index)} title="Remove from watchlist">
          <Icon icon={CrossIcon} />
        </div>
      </div>
    {/each}
  </div>
</div>
