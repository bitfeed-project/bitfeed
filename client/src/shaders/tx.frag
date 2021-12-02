varying lowp vec4 vColor;

void main() {
  gl_FragColor = vColor;
  // premultiply alpha
  gl_FragColor.rgb *= gl_FragColor.a;
}
