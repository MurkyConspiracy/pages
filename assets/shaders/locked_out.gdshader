shader_type canvas_item;

uniform float line_count : hint_range(5.0, 50.0) = 20.0;
uniform float line_brightness : hint_range(0.0, 1.0) = 0.5;
uniform float roll_speed : hint_range(0.0, 0.5) = 0.08;
uniform float line_thickness : hint_range(0.0, 1.0) = 0.3;
uniform float background_darkness : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    vec4 original = texture(TEXTURE, UV);
    
    // Darken the base color
    vec3 color = original.rgb * background_darkness;
    
    // Diagonal movement
    float diagonal_pos = UV.x + UV.y - TIME * roll_speed;
    
    // Create repeating pattern
    float pattern = fract(diagonal_pos * line_count);
    
    // Make distinct gray lines
    float line = step(1.0 - line_thickness, pattern);
    
    // Add lighter gray lines
    color = mix(color, vec3(0.5), line * line_brightness);
    
    COLOR = vec4(color, original.a);
}