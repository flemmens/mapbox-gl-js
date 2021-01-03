uniform float u_fade_t;
uniform float u_opacity;
uniform sampler2D u_image0;
uniform sampler2D u_image1;
varying vec2 v_pos0;
varying vec2 v_pos1;

uniform float u_brightness_low;
uniform float u_brightness_high;

uniform float u_saturation_factor;
uniform float u_contrast_factor;
uniform vec3 u_spin_weights;

uniform vec4 u_unpack;

float getElevation() {
    // Convert encoded elevation value to meters
    vec4 data = texture2D(u_image0, v_pos0) * 255.0;
    data.a = -1.0;
    return dot(data, u_unpack) / 4.0;
}

void main() {

/*
    // read and cross-fade colors from the main and parent tiles
    vec4 color0 = texture2D(u_image0, v_pos0);
    vec4 color1 = texture2D(u_image1, v_pos1);
    if (color0.a > 0.0) {
        color0.rgb = color0.rgb / color0.a;
    }
    if (color1.a > 0.0) {
        color1.rgb = color1.rgb / color1.a;
    }
    vec4 color = mix(color0, color1, u_fade_t);
    color.a *= u_opacity;
    vec3 rgb = color.rgb;

    // spin
    rgb = vec3(
        dot(rgb, u_spin_weights.xyz),
        dot(rgb, u_spin_weights.zxy),
        dot(rgb, u_spin_weights.yzx));

    // saturation
    float average = (color.r + color.g + color.b) / 3.0;
    rgb += (average - rgb) * u_saturation_factor;

    // contrast
    rgb = (rgb - 0.5) * u_contrast_factor + 0.5;

    // brightness
    vec3 u_high_vec = vec3(u_brightness_low, u_brightness_low, u_brightness_low);
    vec3 u_low_vec = vec3(u_brightness_high, u_brightness_high, u_brightness_high);

//    gl_FragColor = vec4(mix(u_high_vec, u_low_vec, rgb) * color.a, color.a);
//    gl_FragColor = vec4(1.0,0.0,0.0,1.0);
*/

  // ramp
  vec4 colours[5];
  colours[0] = vec4(0.1,  0.1, 0.5, 0.0);
  colours[1] = vec4(0.4, 0.55, 0.3, 1.0);
  colours[2] = vec4(0.9,  0.9, 0.6, 5000.0);
  colours[3] = vec4(0.6,  0.4, 0.3, 20000.0);
  colours[4] = vec4(1.0,  1.0, 1.0, 40000.0);

  highp vec4  color = texture2D(u_image0, v_pos0);
  highp float height = (
		color.r * 255.0 * 256.0 * 256.0 +
		color.g * 255.0 * 256.0 +
		color.b * 255.0 )
	-100000.0;

  gl_FragColor.rgb = colours[0].rgb;

	for (int i=0; i < 4; i++) {
		gl_FragColor.rgb = mix(
			gl_FragColor.rgb,
			colours[i+1].rgb,
			smoothstep( colours[i].a, colours[i+1].a, height )
		);
	}
	gl_FragColor.a = 1.;

//  gl_FragColor = color;
//  gl_FragColor = vec4(0.0, 0.0, 0.0, col.g);


#ifdef OVERDRAW_INSPECTOR
    gl_FragColor = vec4(1.0);
#endif
}
