varying lowp vec4 vColor;

attribute float startTime;
attribute float zIndex;
attribute float speed;
attribute vec4 positions;
attribute vec2 sizes;
attribute vec2 colors;
attribute vec2 palettes;
attribute vec2 alphas;

uniform vec2 screenSize;
uniform float now;
// uniform float opacityTarget;        // target opacity for fading points
uniform sampler2D colorTexture;

vec3 selectPalette(float index) {
  if (index < 2.0) {
    return vec3(0.97, 0.58, 0.1);
  } else {
    return vec3(0.0, 1.0, 0.8);
  }
}

void main() {
  vec4 screenTransform = vec4(2.0 / screenSize.x, -2.0 / screenSize.y, -1.0, 1.0);

  float delta = clamp((now - startTime) * speed, 0.0, 1.0);

  vec2 position = mix(positions.xy, positions.zw, delta);
  gl_PointSize = mix(sizes.x, sizes.y, delta);
  gl_Position = vec4(position * screenTransform.xy + screenTransform.zw, zIndex, 1.0);

  float colorIndex = mix(colors.x, colors.y, delta);
  float alpha = mix(alphas.x, alphas.y, delta);
  if (palettes.y < 1.0) { // texture color
    vec4 texel = texture2D(colorTexture, vec2(colorIndex, 0.0));
    vColor = vec4(texel.rgb, alpha);
  } else { // preset color
    vec3 startColor = selectPalette(palettes.x);
    vec3 endColor = selectPalette(palettes.y);
    vec3 color = mix(startColor, endColor, colorIndex);
    vColor = vec4(color, alpha);
  }
}
