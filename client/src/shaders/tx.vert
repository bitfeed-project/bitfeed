varying lowp vec4 vColor;

// each attribute contains [x: startValue, y: endValue, z: startTime, w: rate]
// shader interpolates between start and end values at the given rate, from the given time

attribute vec2 offset;
attribute vec4 posX;
attribute vec4 posY;
attribute vec4 posR;
attribute vec4 hues;
attribute vec4 lights;
attribute vec4 alphas;

uniform vec2 screenSize;
uniform float now;
uniform sampler2D colorTexture;

// hue is modular, so interpolation should take the shortest path, wrapping around if necessary
float interpolateHue(vec4 hue) {
  float delta = clamp((now - hue.z) * hue.w, 0.0, 1.0);
  if (abs(hue.x - hue.y) > 0.5) {
    if (hue.x > 0.5) {
      return mod(mix(hue.x - 1.0, hue.y, delta), 1.0);
    } else {
      return mod(mix(hue.x, hue.y - 1.0, delta), 1.0);
    }
  } else {
    return mix(hue.x, hue.y, delta);
  }
}

float interpolateAttribute(vec4 attr) {
  float delta = clamp((now - attr.z) * attr.w, 0.0, 1.0);
  return mix(attr.x, attr.y, delta);
}

void main() {
  vec4 screenTransform = vec4(2.0 / screenSize.x, 2.0 / screenSize.y, -1.0, -1.0);
  // vec4 screenTransform = vec4(1.0 / screenSize.x, 1.0 / screenSize.y, -0.5, -0.5);

  float radius = interpolateAttribute(posR);
  vec2 position = vec2(interpolateAttribute(posX), interpolateAttribute(posY)) + (radius * offset);

  gl_Position = vec4(position * screenTransform.xy + screenTransform.zw, 1.0, 1.0);

  float hue = interpolateHue(hues);
  float light = interpolateAttribute(lights);
  float alpha = interpolateAttribute(alphas);

  // interpolate across texture
  vec4 texel = texture2D(colorTexture, vec2(light, hue));
  vColor = vec4(texel.rgb, alpha);
}
