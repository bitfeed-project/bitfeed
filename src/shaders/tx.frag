varying lowp vec4 vColor;

void main() {
  gl_FragColor = vColor;
  gl_FragColor.rgb *= gl_FragColor.a;
  // gl_FragColor = vec4(0.0, 1.0, 0.0, 1.0);
}
