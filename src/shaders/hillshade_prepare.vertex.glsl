uniform mat4 u_matrix;
// uniform vec2 u_dimension;

vec2 u_dimension = vec2(260.0, 260.0);

attribute vec2 a_pos;
attribute vec2 a_texture_pos;

varying vec2 v_pos;

void main() {
  gl_Position = u_matrix * vec4(a_pos, 0.0, 1.0);

  // Positionne les tiles en superposition de 1px ? u_dimension = 258

  highp vec2 epsilon = 1.0 / u_dimension;
  float scale = (u_dimension.x - 2.0) / u_dimension.x;
  v_pos = (a_texture_pos / 8192.0) * scale + epsilon;
}
