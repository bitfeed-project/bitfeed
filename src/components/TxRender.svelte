<script>
  import { onMount } from 'svelte'
  import vertShaderSrc from '../shaders/tx.vert'
  import fragShaderSrc from '../shaders/tx.frag'
  import { interpolateHcl } from 'd3-interpolate'
  import { color } from 'd3-color'
  import { darkMode } from '../stores.js'

  export let txs = []
  let canvas
  let gl
  let shaderProgram
  let aspectRatio
  let sceneScale = [1.0, 1.0]
  let lastTime = 0.0

  // Vertex information
  let pointArray

  // Shader uniforms

  // Shader attributes
  let spritePosition
  let spriteAge
  let spriteMode

  // Color map texture
  let colorTexture

  export let running = false

  $: {
    if (running) run()
  }

  function getTxPointArray () {
    const now = Date.now()
    return new Float32Array(txs.flatMap(tx => {
      return [
        tx.p.x, tx.p.y, (now - tx.last), tx.status === 'mined' ? 1.0 : 0.0
      ]
    }))
  }

  function resizeCanvas () {
    var rect = canvas.parentNode.getBoundingClientRect()
    canvas.width = rect.width
    canvas.height = rect.height
  }

  function compileShader(src, type) {
    let shader = gl.createShader(type)

    gl.shaderSource(shader, src)
    gl.compileShader(shader)

    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      console.log(`Error compiling ${type === gl.VERTEX_SHADER ? "vertex" : "fragment"} shader:`)
      console.log(gl.getShaderInfoLog(shader))
    }
    return shader
  }

  function buildShaderProgram(shaderInfo) {
    let program = gl.createProgram()

    shaderInfo.forEach(function(desc) {
      let shader = compileShader(desc.src, desc.type)
      if (shader) {
        gl.attachShader(program, shader)
      }
    })

    gl.linkProgram(program)

    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
      console.log("Error linking shader program:")
      console.log(gl.getProgramInfoLog(program))
    }

    return program
  }

  function run () {
    gl.viewport(0, 0, canvas.width, canvas.height)
    gl.clearColor(0.0, 0.0, 0.0, 0.0)
    gl.clear(gl.COLOR_BUFFER_BIT)

    pointArray = getTxPointArray()

    const glBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, glBuffer)

    if (pointArray.length) {
      gl.bufferData(gl.ARRAY_BUFFER, pointArray, gl.DYNAMIC_DRAW)
    }

    gl.uniform2f(gl.getUniformLocation(shaderProgram, 'screenSize'), 960, 427)
    gl.uniform1f(gl.getUniformLocation(shaderProgram, 'opacityTarget'), $darkMode ? 0.1 : 0.4)

    spritePosition = gl.getAttribLocation(shaderProgram, 'spritePosition');
    gl.enableVertexAttribArray(spritePosition);
    gl.vertexAttribPointer(spritePosition,
        2,  // because it was a vec2
        gl.FLOAT,  // vec2 contains floats
        false,
        4 * 4,   // each value is next to each other
        0);  // starts at start of array
    spriteAge = gl.getAttribLocation(shaderProgram, 'spriteAge');
    gl.enableVertexAttribArray(spriteAge);
    gl.vertexAttribPointer(spriteAge,
        1,  // single
        gl.FLOAT,  // float
        false,
        4 * 4,   // each value is next to each other
        2 * 4);  // starts at start of array
    spriteMode = gl.getAttribLocation(shaderProgram, 'spriteMode');
    gl.enableVertexAttribArray(spriteMode);
    gl.vertexAttribPointer(spriteMode,
        1,  // single
        gl.FLOAT,  // float
        false,
        4 * 4,   // each value is next to each other
        3 * 4);  // starts at start of array

    // Tell WebGL we want to affect texture unit 0
    gl.activeTexture(gl.TEXTURE0)
    // Bind the texture to texture unit 0
    gl.bindTexture(gl.TEXTURE_2D, colorTexture)
    // Tell the shader we bound the texture to texture unit 0
    gl.uniform1i(gl.getUniformLocation(shaderProgram, 'colorTexture'), 0);

    gl.drawArrays(gl.POINTS, 0, pointArray.length / 3)

    window.requestAnimationFrame(currentTime => {
      lastTime = currentTime
      if (running) run()
    })
  }

  function loadColorTexture(gl, colorA, colorB, width) {
    const texture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, texture);

    const interpolator = interpolateHcl(colorA, colorB)

    const colors = [...Array(width).keys()].flatMap(step => {
      let rgb = color(interpolator(step / width)).rgb()
      return [
        rgb.r,
        rgb.g,
        rgb.b,
        255
      ]
    })
    console.log('pixels', colors)

    const level = 0;
    const internalFormat = gl.RGBA;
    const height = 1;
    const border = 0;
    const srcFormat = gl.RGBA;
    const srcType = gl.UNSIGNED_BYTE;
    const pixels = new Uint8Array(
      colors
    )

    gl.texImage2D(gl.TEXTURE_2D, level, internalFormat,
                  width, height, border, srcFormat, srcType,
                  pixels);

    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);

    return texture;
  }

  onMount(() => {
    resizeCanvas()
    gl = canvas.getContext('webgl')

    gl.clearColor(0.0, 0.0, 0.0, 0.0)
    gl.clear(gl.COLOR_BUFFER_BIT)

    const shaderSet = [
      {
        type: gl.VERTEX_SHADER,
        src: vertShaderSrc
      },
      {
        type: gl.FRAGMENT_SHADER,
        src: fragShaderSrc
      }
    ]

    shaderProgram = buildShaderProgram(shaderSet)

    gl.useProgram(shaderProgram)

    gl.enable(gl.BLEND);
    gl.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA);

    colorTexture = loadColorTexture(gl, '#f7941d', 'rgb(0%,100%,80%)', 500);

    running = true
  })
</script>

<style>
.tx-layer {
  position: absolute;
  left: 0;
  right: 0;
  top: -5px;
  bottom: 0;
  pointer-events: none;
  overflow: hidden;
}
</style>

<svelte:window on:resize={resizeCanvas} />

<canvas
  class="tx-layer"
  bind:this={canvas}
></canvas>
