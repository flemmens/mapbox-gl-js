#ifdef GL_ES
precision highp float;
#endif

uniform sampler2D u_image;
varying vec2 v_pos;

void main() {
  // recopie juste le hillshadePrepare, comprend pas l'utilité ??

  gl_FragColor = texture2D(u_image, v_pos);
}
