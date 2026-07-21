shader_type canvas_item;

// Samples the screen texture and applies gamma, brightness, and contrast adjustments
// Apply this shader to a ColorRect that covers the entire screen

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// Range: 0.5 to 1.5, default 1.0 (no change)
uniform float gamma : hint_range(0.5, 1.5, 0.01) = 1.0;
// Range: -0.9 to 0.1, default 0.0 (no change)
uniform float brightness : hint_range(-0.9, 0.1, 0.01) = 0.0;
// Range: 0.75 to 1.25, default 1.0 (no change)
uniform float contrast : hint_range(0.75, 1.25, 0.01) = 1.0;

void fragment() {
	// Sample the current screen color
	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	
	// Apply brightness (additive)
	vec3 color = screen_color.rgb + vec3(brightness);
	
	// Apply contrast (centered around 0.5 gray)
	color = (color - 0.5) * contrast + 0.5;
	
	// Apply gamma correction (inverse gamma for display)
	color = pow(max(color, vec3(0.0)), vec3(1.0 / gamma));
	
	// Clamp to valid range and output
	COLOR = vec4(clamp(color, 0.0, 1.0), screen_color.a);
}
