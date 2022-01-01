<script>
import { createEventDispatcher } from 'svelte'

const dispatch = createEventDispatcher();

export let value = 0
export let max = 100000000
export let logScale = false
export let thresholds = []

let trackElement, trackBounds
let dragging = false

let marks = []
$: {
  if (thresholds && thresholds.length) {
    marks = thresholds.map(thresh => {
      return {
        ...thresh,
        style: `left: ${percentOfScale(thresh.minSats, max)}%; --mark-bg: ${thresh.color};`
      }
    })
  }
}

let activeThreshold = {}
$: {
  activeThreshold = {}
  if (thresholds && value != null) {
    thresholds.forEach(thresh => {
      if (value >= thresh.minSats) activeThreshold = thresh
    })
  }
}

let handleStyle
$: {
  handleStyle = `left: ${percentOfScale(value, max)}%; background-color: ${activeThreshold.color || 'var(--grey)'}`
}

let trackStyle
$: {
  trackStyle = `right: ${100 - percentOfScale(value, max)}%; --track-bg: ${activeThreshold.color || 'var(--grey)'}`
}

function percentOfScale (amount, max=100000000, min=100) {
  let percent
  if (logScale) {
    let logMin = Math.log10(min)
    percent = (Math.max(0,Math.log10(amount) - logMin) / (Math.log10(max) - logMin)) * 100
  } else {
    percent = (amount / max) * 100
  }
  return Math.min(percent, 100)
}

function toScale (fraction, max=100000000, min=100) {
  if (logScale) {
    let logMin = Math.log10(min)
    const raw = Math.pow(10, (fraction * (Math.log10(max) - logMin)) + logMin)
    const clamped = Math.min(max, Math.max(min, raw))
    return Math.round(clamped)
  } else {
    return Math.round(fraction * max)
  }
}

function startDrag (e) {
  if (trackElement) {
    trackBounds = trackElement.getBoundingClientRect()
    cancelDrag()
    dragging = true
    window.addEventListener('pointermove', onDrag)
    window.addEventListener('pointerup', cancelDrag)
    window.addEventListener('pointercancel', cancelDrag)
    onDrag(e)
  }

}

function onDrag (e) {
  const dx = e.pageX - trackBounds.left
  const fraction = dx / trackBounds.width
  const newValue = toScale(fraction, max)
  dispatch('input', newValue)
}

function cancelDrag (e) {
  dragging = false
  window.removeEventListener('pointermove', onDrag)
  window.removeEventListener('pointerup', cancelDrag)
  window.removeEventListener('pointercancel', cancelDrag)
}

</script>

<div class="satoshi-slider">
  <div class="track" class:dragging={dragging} bind:this={trackElement}>
    <div class="filled-track" style={trackStyle} />
    <div class="marks">
      {#each marks as mark }
        <div
          class="mark"
          class:active={value >= mark.minSats}
          class:over={value >= mark.maxSats}
          style={mark.style}
        >
          <div class="tick" />
          <span class="bubble-icon" title={mark.title}>{ mark.emoji }</span>
        </div>
      {/each}
    </div>
    <span class="handle" style={handleStyle} on:pointerdown={startDrag}/>
  </div>
</div>

<style type="text/scss">
  .satoshi-slider {
    width: 100%;
    position: relative;

    .track {
      position: relative;
      width: calc(100% - 40px);
      left: 20px;
      height: 20px;
      border-radius: 10px;
      background: var(--palette-e);
      margin: 60px 0 20px;

      .filled-track {
        position: absolute;
        left: 0;
        top: 0;
        bottom: 0;
        border-top-left-radius: 10px;
        border-bottom-left-radius: 10px;
        --track-bg: var(--bold-a);
        background: var(--track-bg);
        box-shadow: 0px 0px 20px -5px var(--track-bg);
        transition: all 200ms ease-in-out;
      }

      .handle {
        position: absolute;
        top: 0;
        bottom: 0;
        width: 10px;
        height: 10px;
        border-radius: 50%;
        border: solid 5px var(--palette-x);
        cursor: pointer;
        transform: translateX(-50%);
        transition: all 200ms ease-in-out;
      }

      .mark {
        position: absolute;
        top: -15px;
        bottom: 0px;
        transform: translateX(-50%);
        user-select: none;
        --mark-bg: var(--palette-e);

        .tick {
          width: 1px;
          height: 100%;
          border-left: dashed 3px var(--palette-x);
        }

        .bubble-icon {
          position: absolute;
          left: 0;
          top: -20px;
          transform: translate(-50%,-50%) scale(0.75);
          font-size: 2em;
          transition: all 200ms;

          &:before {
            content: '';
            position: absolute;
            left: 50%;
            top: 50%;
            width: 1%;
            padding-bottom: 1%;
            border-radius: 50%;
            background: var(--palette-e);
            z-index: -1;
            transition: all 200ms cubic-bezier(.47,1.52,1,1.32);
          }
        }

        &.active {
          .bubble-icon {
            transform: translate(-50%,-50%) scale(1.2);
          }
          .bubble-icon:before {
            left: 10%;
            top: 10%;
            width: 80%;
            padding-bottom: 80%;
            background: var(--mark-bg);
            box-shadow: 0px 0px 20px -5px var(--mark-bg);
          }
        }
        &.over {
          .bubble-icon {
            transform: translate(-50%,-50%) scale(1);
          }
          .bubble-icon:before {
            left: 20%;
            top: 20%;
            width: 60%;
            padding-bottom: 60%;
            box-shadow: none;
            box-shadow: 0px 0px 10px 0px var(--mark-bg);
          }
        }
      }

      &.dragging {
        .handle, .filled-track {
          transition: all 0s;
        }
      }
    }
  }
</style>
