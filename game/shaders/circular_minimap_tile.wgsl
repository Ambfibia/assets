#import bevy_ui::ui_vertex_output::{UiVertexOutput}

struct CircularMinimapTileUniforms {
    // xy = top-left, zw = size, normalized to the source 512x512 tile.
    source_uv: vec4<f32>,
    // xy = top-left, zw = size, normalized to the 148x148 minimap viewport.
    destination_uv: vec4<f32>,
}

@group(1) @binding(0)
var<uniform> material: CircularMinimapTileUniforms;
@group(1) @binding(1)
var color_texture: texture_2d<f32>;
@group(1) @binding(2)
var color_sampler: sampler;
@group(1) @binding(3)
var alpha_texture: texture_2d<f32>;
@group(1) @binding(4)
var alpha_sampler: sampler;

@fragment
fn fragment(in: UiVertexOutput) -> @location(0) vec4<f32> {
    let minimap_uv = material.destination_uv.xy + in.uv * material.destination_uv.zw;
    let source_uv = material.source_uv.xy + in.uv * material.source_uv.zw;
    let color = textureSample(color_texture, color_sampler, source_uv);
    // The original MiniMapRender fixed-function shader performs
    // `combine previous, texture` with `nanocom_minimap_a` as _DecalTex.
    // Preserve its authored one-pixel antialiasing and cyan rim instead of
    // approximating the shape with a CSS/analytic circle.
    let mask = textureSample(alpha_texture, alpha_sampler, minimap_uv);
    return color * mask;
}
