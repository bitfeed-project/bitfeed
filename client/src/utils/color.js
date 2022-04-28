import { hcl } from 'd3-color'

export function hlToHex ({h, l}) {
  return hcl(h * 360, 78.225, l * 150).hex()
}

export function mixColor (startColor, endColor, min, max, value) {
  const dx = Math.max(0, Math.min(1, (value - min) / (max - min)))
  return {
    h: startColor.h + (dx *(endColor.h - startColor.h)),
    l: startColor.l + (dx *(endColor.l - startColor.l))
  }
}

export const pink = { h: 0.03, l: 0.35 }
export const bluegreen = { h: 0.45, l: 0.4 }
export const orange = { h: 0.181, l: 0.472 }
export const teal = { h: 0.475, l: 0.55 }
export const blue = { h: 0.5, l: 0.55 }
export const green = { h: 0.37, l: 0.35 }
export const purple = { h: 0.95, l: 0.35 }

export const highlightA = { h: 0.93, l: 0.5 } //pink
export const highlightB = { h: 0.214, l: 0.62 } // green
export const highlightC = { h: 0.30, l: 1.0 } // white
export const highlightD = { h: 0.42, l: 0.35 } // blue
export const highlightE = { h: 0.12, l: 0.375 } // red
