shader_type canvas_item;

uniform float glitch_amount : hint_range(0.0, 1.0) = 0.1;
uniform float shear_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float rgb_split : hint_range(0.0, 0.05) = 0.01;

// Pixel glitch parameters
uniform float pixel_frequency : hint_range(0.0, 0.1) = 0.005;
uniform float pixel_brightness : hint_range(0.0, 1.0) = 0.8;
uniform float pixel_size : hint_range(0.1, 5.0) = 0.5;
uniform float pixel_variation : hint_range(0.0, 1.0) = 0.3;

// Speed/burst parameters
uniform float shear_speed : hint_range(0.0, 10.0) = 2.0;
uniform float shear_burst_frequency : hint_range(0.1, 5.0) = 1.0;
uniform float pixel_speed : hint_range(0.0, 10.0) = 4.0;
uniform float pixel_burst_frequency : hint_range(0.1, 5.0) = 2.0;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {

    // Start with base UV
    vec2 uv = UV;

    // Burst control for shearing
    float shear_burst_time = TIME * shear_burst_frequency;
    float shear_burst = step(0.5, fract(shear_burst_time)) * step(random(vec2(floor(shear_burst_time))), 0.7);

    // Horizontal line shearing
    float time_step = floor(TIME * shear_speed);
    float line = floor(uv.y * 15.0);
    float line_noise = random(vec2(line, time_step));

    float displacement = 0.0;
    if (line_noise > (1.0 - shear_intensity * 0.5) && shear_burst > 0.5) {
        displacement = (random(vec2(line + 1.0, time_step)) - 0.5) * shear_intensity * 0.1;
    }

    vec2 sheared_uv = vec2(uv.x + displacement, uv.y);

    // Sample texture with proper wrapping
    vec4 tex_r = texture(TEXTURE, sheared_uv + vec2(rgb_split * shear_burst, 0.0));
    vec4 tex_g = texture(TEXTURE, sheared_uv);
    vec4 tex_b = texture(TEXTURE, sheared_uv - vec2(rgb_split * shear_burst, 0.0));

    vec3 color = vec3(tex_r.r, tex_g.g, tex_b.b);
    float alpha = tex_g.a;

    // Burst control for pixels
    float pixel_burst_time = TIME * pixel_burst_frequency;
    float pixel_burst = step(0.5, fract(pixel_burst_time)) * step(random(vec2(floor(pixel_burst_time) + 100.0)), 0.6);

    // Random pixel corruption
    if (alpha > 0.1 && pixel_burst > 0.5) {
        vec2 pixel_pos = floor(UV * (1000.0 / pixel_size));
        float pixel_time = floor(TIME * pixel_speed);

        float area_noise = random(floor(pixel_pos / 10.0) + vec2(pixel_time));

        if (area_noise > 0.8) {
            float pixel_noise = random(pixel_pos + vec2(pixel_time * 123.456, 0.0));

            if (pixel_noise > (1.0 - pixel_frequency)) {
                float color_choice = random(pixel_pos + vec2(pixel_time, 100.0));

                float variation1 = random(pixel_pos + vec2(pixel_time, 200.0)) * pixel_variation;
                float variation2 = random(pixel_pos + vec2(pixel_time, 300.0)) * pixel_variation;

                if (color_choice < 0.33) {
                    color = vec3(pixel_brightness, variation1, variation2);
                } else if (color_choice < 0.66) {
                    color = vec3(variation1, pixel_brightness, variation2);
                } else {
                    color = vec3(variation1, variation2, pixel_brightness);
                }
            }
        }
    }

    COLOR = vec4(color, alpha);
}