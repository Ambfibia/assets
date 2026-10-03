#import bevy_ui::ui_vertex_output::{UiVertexOutput}

struct FusionMatterMeterUniforms {
    // x = current Fusion Matter / maximum Fusion Matter.
    // yz = source `fPivotPoint` in local normalized texture coordinates.
    parameters: vec4<f32>,
}

@group(1) @binding(0)
var<uniform> material: FusionMatterMeterUniforms;
@group(1) @binding(1)
var color_texture: texture_2d<f32>;
@group(1) @binding(2)
var color_sampler: sampler;
@group(1) @binding(3)
var right_color_texture: texture_2d<f32>;
@group(1) @binding(4)
var right_color_sampler: sampler;
@group(1) @binding(5)
var left_mask_texture: texture_2d<f32>;
@group(1) @binding(6)
var left_mask_sampler: sampler;
@group(1) @binding(7)
var rotating_mask_texture: texture_2d<f32>;
@group(1) @binding(8)
var rotating_mask_sampler: sampler;

fn source_over(base: vec4<f32>, layer: vec4<f32>) -> vec4<f32> {
    let output_alpha = layer.a + base.a * (1.0 - layer.a);
    if output_alpha <= 0.0 {
        return vec4<f32>(0.0);
    }
    let output_rgb = (
        layer.rgb * layer.a + base.rgb * base.a * (1.0 - layer.a)
    ) / output_alpha;
    return vec4<f32>(output_rgb, output_alpha);
}

fn sample_rotated_right_mask(uv: vec2<f32>, pivot: vec2<f32>, angle: f32) -> vec4<f32> {
    // GUIUtility.RotateAroundPivot rotates clockwise in top-left screen
    // coordinates. Texture sampling applies the inverse transform.
    let delta = uv - pivot;
    let sine = sin(angle);
    let cosine = cos(angle);
    let source_uv = pivot + vec2<f32>(
        cosine * delta.x + sine * delta.y,
        -sine * delta.x + cosine * delta.y,
    );
    if any(source_uv < vec2<f32>(0.0)) || any(source_uv > vec2<f32>(1.0)) {
        return vec4<f32>(0.0);
    }
    return textureSample(rotating_mask_texture, rotating_mask_sampler, source_uv);
}

@fragment
fn fragment(in: UiVertexOutput) -> @location(0) vec4<f32> {
    let fill = clamp(material.parameters.x, 0.0, 1.0);
    let regular = textureSample(color_texture, color_sampler, in.uv);
    if fill >= 1.0 {
        return regular;
    }

    // Exact cnGUINanocom draw order:
    //   FMBar
    //   RotateAroundPivot(fDegree); rtBackImage2Right
    //   fDegree > 180 ? FMBarRight : rtBackImage2Left
    // The black masks are intentionally retained. Discarding the unfilled
    // arc made the world/minimap show through and did not read as a percentage.
    let angle = fill * 2.0 * 3.141592653589793;
    let rotating_mask = sample_rotated_right_mask(in.uv, material.parameters.yz, angle);
    var output = source_over(regular, rotating_mask);
    if fill > 0.5 {
        output = source_over(
            output,
            textureSample(right_color_texture, right_color_sampler, in.uv),
        );
    } else {
        output = source_over(
            output,
            textureSample(left_mask_texture, left_mask_sampler, in.uv),
        );
    }
    return output;
}
