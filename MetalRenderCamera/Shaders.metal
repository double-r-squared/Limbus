//
//  Shaders.metal
//  MetalShaderCamera
//
//  Created by Alex Staravoitau on 28/04/2016.
//  Copyright © 2016 Old Yellow Bricks. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

constant bool deviceSupportsNonuniformThreadgroups [[ function_constant(0) ]];


typedef struct {
    float4 renderedCoordinate [[position]];
    float2 textureCoordinate;
} TextureMappingVertex;

vertex TextureMappingVertex mapTexture(unsigned int vertex_id [[ vertex_id ]]) {
    float4x4 renderedCoordinates = float4x4(float4( -1.0, -1.0, 0.0, 1.0 ),
                                            float4(  1.0, -1.0, 0.0, 1.0 ),
                                            float4( -1.0,  1.0, 0.0, 1.0 ),
                                            float4(  1.0,  1.0, 0.0, 1.0 ));

    float4x2 textureCoordinates = float4x2(float2( 0.0, 1.0 ),
                                           float2( 1.0, 1.0 ),
                                           float2( 0.0, 0.0 ),
                                           float2( 1.0, 0.0 ));
    TextureMappingVertex outVertex;
    outVertex.renderedCoordinate = renderedCoordinates[vertex_id];
    outVertex.textureCoordinate = textureCoordinates[vertex_id];
    
    return outVertex;
}

fragment half4 displayTexture(TextureMappingVertex mappingVertex [[ stage_in ]],
                              texture2d<float, access::sample> texture [[ texture(0) ]],
                              constant float &threshold [[ buffer(1) ]],
                              constant float &brightness [[ buffer(2) ]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = mappingVertex.textureCoordinate;
    
    // Sample base color
    float4 color = texture.sample(s, uv);
    float luminance = dot(color.rgb, float3(0.299, 0.587, 0.114));
    float binary = step(threshold, luminance);

    // === Draw 100x100 px white box centered at (0.5, 0.5) ===
    // Hardcoded for 1280x720 texture (adjust if your texture is a different size)
    float2 textureSize = float2(1290.0, 2796.0);
    float2 boxSizeUV = float2(100.0 / textureSize.x, 100 / textureSize.y);
    float2 halfSize = boxSizeUV * 0.5;
    float2 center = float2(0.5, 0.5);

    float border = 0.002;

    bool inBoxX = uv.x > (center.x - halfSize.x) && uv.x < (center.x + halfSize.x);
    bool inBoxY = uv.y > (center.y - halfSize.y) && uv.y < (center.y + halfSize.y);

    bool nearLeft   = abs(uv.x - (center.x - halfSize.x)) < border;
    bool nearRight  = abs(uv.x - (center.x + halfSize.x)) < border;
    bool nearTop    = abs(uv.y - (center.y + halfSize.y)) < border;
    bool nearBottom = abs(uv.y - (center.y - halfSize.y)) < border;

    if ((inBoxX && (nearTop || nearBottom)) || (inBoxY && (nearLeft || nearRight))) {
        return half4(brightness, 1 - brightness, 0.0, 1.0); // white box outline
    }

    return half4(color);
}



// MARK: - Calibration

kernel void analyzeCenterRegion(
    texture2d<float, access::sample> inTexture [[ texture(0) ]],
    device float* resultBuffer [[ buffer(0) ]],
    uint2 gid [[ thread_position_in_grid ]]
) {
    if (gid.x != 0 || gid.y != 0) return;

    constexpr sampler s(address::clamp_to_edge, filter::linear);

    ushort2 textureSize = ushort2(inTexture.get_width(), inTexture.get_height());
    int2 center = int2(textureSize) / 2;
    int regionHalf = 50;

    float sum = 0.0;
    int count = 0.0;

    for (int y = -regionHalf; y < regionHalf; y++) {
        for (int x = -regionHalf; x < regionHalf; x++) {
            int2 pixel = center + int2(x, y);

            // ✅ Prevent out-of-bounds reads
            if (pixel.x < 0 || pixel.y < 0 || pixel.x >= textureSize.x || pixel.y >= textureSize.y) {
                continue;
            }

            float2 uv = (float2(pixel) + 0.5) / float2(textureSize);
            float4 color = inTexture.sample(s, uv);
            float brightness = (color.r + color.g + color.b) / 3.0;

            sum += brightness;
            count += 1;
        }
    }

    resultBuffer[0] = count > 0 ? (sum / float(count)) : 0.0;
}

