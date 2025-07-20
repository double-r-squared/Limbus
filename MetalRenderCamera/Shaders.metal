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

    // === Draw expanding circle centered at (0.5, 0.5) ===
    float2 textureSize = float2(1290.0, 2796.0);
    float2 center = float2(0.5, 0.5);
    
    // Calculate distance from center in UV space
    float2 delta = uv - center;
    
    // Account for aspect ratio to make a perfect circle
    float aspectRatio = textureSize.x / textureSize.y;
    delta.x *= aspectRatio;
    
    float distance = length(delta);
    
    // Circle radius based on brightness (0.0 to 1.0 maps to 0 to ~0.2 in UV space)
    float maxRadius = 0.2;
    float radius = brightness * maxRadius;
    
    // Circle outline thickness
    float outlineThickness = 0.005;
    
    // Check if we're within the circle outline
    bool inCircleOutline = distance >= (radius - outlineThickness) && distance <= (radius + outlineThickness);
    
    if (inCircleOutline && radius > 0.01) { // Only draw if radius is meaningful
        // Color changes based on brightness
        // Low brightness = red/orange, high brightness = blue/cyan
        float3 circleColor;
        if (brightness < 0.5) {
            // Red to yellow transition
            circleColor = mix(float3(1.0, 0.0, 0.0), float3(1.0, 1.0, 0.0), brightness * 2.0);
        } else {
            // Yellow to cyan transition
            circleColor = mix(float3(1.0, 1.0, 0.0), float3(0.0, 1.0, 1.0), (brightness - 0.5) * 2.0);
        }
        
        return half4(half3(circleColor), 1.0);
    }
    
    // === Draw center cross ===
    float crossSize = 0.02; // Half-length of cross arms in UV space
    float crossThickness = 0.002; // Thickness of cross lines
        
    // Check if we're on the horizontal line of the cross
    bool onHorizontalLine = abs(uv.y - center.y) < crossThickness &&
                           abs(uv.x - center.x) < crossSize;
    
    // Check if we're on the vertical line of the cross
    // Apply aspect ratio correction to vertical thickness and size
    bool onVerticalLine = abs(uv.x - center.x) < (crossThickness / aspectRatio) &&
                         abs(uv.y - center.y) < (crossSize * aspectRatio);
    
    if (onHorizontalLine || onVerticalLine) {
        return half4(1.0, 1.0, 1.0, 1.0); // White cross
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
    float2 center = float2(textureSize) * 0.5;
    
    // Match the cross dimensions from the fragment shader
    float crossSize = 0.02; // Half-length of cross arms in UV space
    float crossThickness = 0.002; // Thickness of cross lines
    
    // Convert UV space dimensions to pixel space
    int crossSizePixels = int(crossSize * float(textureSize.x));
    int crossThicknessPixels = max(1, int(crossThickness * float(textureSize.x)));

    float sum = 0.0;
    int count = 0;

    // Analyze the horizontal arm of the cross
    for (int y = -crossThicknessPixels; y <= crossThicknessPixels; y++) {
        for (int x = -crossSizePixels; x <= crossSizePixels; x++) {
            int2 pixel = int2(center) + int2(x, y);

            // Prevent out-of-bounds reads
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

    // Analyze the vertical arm of the cross (avoiding double-counting the center intersection)
    for (int y = -crossSizePixels; y <= crossSizePixels; y++) {
        for (int x = -crossThicknessPixels; x <= crossThicknessPixels; x++) {
            // Skip the horizontal section we already counted
            if (abs(y) <= crossThicknessPixels) {
                continue;
            }
            
            int2 pixel = int2(center) + int2(x, y);

            // Prevent out-of-bounds reads
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
