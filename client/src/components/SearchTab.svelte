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
import { highlight, newHighlightQuery, highlightingFull } from '../stores.js'
import { hcl } from 'd3-color'

const highlightColors = [
  { h: 0.03, l: 0.35 },
  { h: 0.40, l: 0.35 },
  { h: 0.65, l: 0.35 },
  { h: 0.85, l: 0.35 },
  { h: 0.12, l: 0.35 },
]
const highlightHexColors = highlightColors.map(c => hclToHex(c))
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
let queryColor
let queryColorHex
let watchlist = []

init ()

setNextColor()

$: {
  if ($newHighlightQuery) {
    matchedQuery = matchQuery($newHighlightQuery)
    if (matchedQuery) {
      matchedQuery.color = queryColor
      matchedQuery.colorHex = queryColorHex
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
    if (matchedQuery) {
      matchedQuery.color = queryColor
      matchedQuery.colorHex = queryColorHex
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
        const i = highlightHexColors.findIndex(c => c === q.colorHex)
        if (i >= 0) usedColors[i] = q.colorHex
        else console.log('unknown color')
      })
    } catch (e) {
      console.log('failed to parse cached highlight queries')
    }
  }
}

function setNextColor () {
  const nextIndex = usedColors.findIndex(used => !used)
  if (nextIndex >= 0) {
    queryColor = highlightColors[nextIndex]
    queryColorHex = highlightHexColors[nextIndex]
    usedColors[nextIndex] = queryColorHex
  }
}
function clearUsedColor (hex) {
  const clearIndex = usedColors.findIndex(used => used === hex)
  usedColors[clearIndex] = false
}

function hclToHex (color) {
  return hcl(color.h * 360, 78.225, color.l * 150).hex()
}

async function add () {
  if (matchedQuery && !$highlightingFull) {
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
    clearUsedColor(removed[0].colorHex)
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
  add()
  return false
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
        <input class="search-input" type="text" bind:value={query} placeholder="Enter an address or txid...">
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
    {#each watchlist as watched, index (watched.colorHex)}
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
