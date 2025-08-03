//
//  CorneaMap.swift
//  Metal Camera
//
//  Created by Nate  on 7/21/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//
import SwiftUI
import CoreGraphics
import UIKit

// MARK: - Zernike 2D Heatmap Extension
extension PatientDetailView {
    
    /// Calculates the actual max radius used in ring analysis
    private var calculatedMaxRadius: Double {
        let size = image.size
        let centerX = size.width / 2
        let centerY = (size.height / 2) + 10
        return min(centerX, centerY) * 0.9
    }
    
    /// Gets the center point used in ring analysis
    private var analysisCenter: CGPoint {
        let size = image.size
        let centerX = size.width / 2
        let centerY = (size.height / 2) + 10
        return CGPoint(x: centerX, y: centerY)
    }
    
    /// Generates a 2D Zernike polynomial heatmap with proper radius matching
    /// - Parameters:
    ///   - overlayOnOriginal: If true, overlays on original image; if false, uses white background
    ///   - imageSize: Size of the output image (defaults to original image size)
    /// - Returns: UIImage with the Zernike heatmap
    func generateZernikeHeatmap(in image: UIImage, overlayOnOriginal: Bool = false, imageSize: CGSize? = nil) -> UIImage {
        
        // Use original image size if not specified
        let targetSize = imageSize ?? image.size
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        // Calculate scaling factors
        let scaleX = targetSize.width / image.size.width
        let scaleY = targetSize.height / image.size.height
        
        // Scale the analysis parameters to match the target size
        let originalCenter = analysisCenter
        let scaledCenter = CGPoint(
            x: originalCenter.x * scaleX,
            y: originalCenter.y * scaleY
        )
        let scaledRadius = calculatedMaxRadius * min(scaleX, scaleY)
        
        let resultImage = renderer.image { context in
            let cgContext = context.cgContext
            
            // Background setup
            if overlayOnOriginal {
                // Draw original image as background, scaled to fit
                let aspectFitRect = aspectFitRect(for: image.size, in: CGRect(origin: .zero, size: targetSize))
                image.draw(in: aspectFitRect)
            } else {
                // White background
                cgContext.setFillColor(UIColor.white.cgColor)
                cgContext.fill(CGRect(origin: .zero, size: targetSize))
            }
            
            // Only generate heatmap if we have Zernike coefficients
            guard !zernikeCoefficients.isEmpty else {
                // Draw a placeholder circle to show the analysis area
                drawCircleBoundary(context: cgContext, center: scaledCenter, radius: scaledRadius, color: UIColor.lightGray, lineWidth: 1.0)
                return
            }
            
            // Create heatmap using the properly scaled parameters
            let pixelData = generateZernikePixelData(
                width: Int(targetSize.width),
                height: Int(targetSize.height),
                centerX: scaledCenter.x,
                centerY: scaledCenter.y,
                radius: scaledRadius
            )
            
            // Apply heatmap overlay
            applyHeatmapOverlay(
                context: cgContext,
                pixelData: pixelData,
                size: targetSize,
                alpha: 1.0  // Always use full opacity
            )
            
            // Draw circle boundary to show the analysis area
            drawCircleBoundary(context: cgContext, center: scaledCenter, radius: scaledRadius, color: UIColor.black, lineWidth: 2.0)
        }
        return resultImage
    }
    
    /// Generates pixel data for Zernike polynomial visualization
    private func generateZernikePixelData(width: Int, height: Int, centerX: CGFloat, centerY: CGFloat, radius: Double) -> [[Double]] {
        
        var pixelData = Array(repeating: Array(repeating: 0.0, count: width), count: height)
        var minValue = Double.infinity
        var maxValue = -Double.infinity
        
        // Calculate Zernike values for each pixel
        for y in 0..<height {
            for x in 0..<width {
                let dx = Double(x) - Double(centerX)
                let dy = Double(y) - Double(centerY)
                let r = sqrt(dx * dx + dy * dy)
                
                // Only calculate within the circle
                if r <= radius {
                    let normalizedR = r / radius
                    let theta = atan2(dy, dx)
                    
                    var zernikeValue = 0.0
                    
                    // Sum all Zernike terms
                    for (index, coefficient) in zernikeCoefficients.enumerated() {
                        if index < zernikeModes.count {
                            let mode = zernikeModes[index]
                            let polynomial = calculateZernikePolynomial(n: mode.n, m: mode.m, rho: normalizedR, theta: theta)
                            zernikeValue += coefficient * polynomial
                        }
                    }
                    pixelData[y][x] = zernikeValue
                    minValue = min(minValue, zernikeValue)
                    maxValue = max(maxValue, zernikeValue)
                }
            }
        }
        
        // Normalize values to 0-1 range
        let range = maxValue - minValue
        if range > 0 {
            for y in 0..<height {
                for x in 0..<width {
                    let dx = Double(x) - Double(centerX)
                    let dy = Double(y) - Double(centerY)
                    let r = sqrt(dx * dx + dy * dy)
                    
                    if r <= radius && pixelData[y][x] != 0.0 {
                        pixelData[y][x] = (pixelData[y][x] - minValue) / range
                    } else if r > radius {
                        pixelData[y][x] = 0.0 // Ensure pixels outside circle are zero
                    }
                }
            }
        }
        return pixelData
    }
    
    /// Calculates individual Zernike polynomial value
    private func calculateZernikePolynomial(n: Int, m: Int, rho: Double, theta: Double) -> Double {
        guard rho <= 1.0 else { return 0.0 }
        
        let radialPart = calculateZernikeRadial(n: n, m: abs(m), rho: rho)
        
        if m >= 0 {
            return radialPart * cos(Double(m) * theta)
        } else {
            return radialPart * sin(Double(abs(m)) * theta)
        }
    }
    
    /// Calculates radial component of Zernike polynomial
    private func calculateZernikeRadial(n: Int, m: Int, rho: Double) -> Double {
        guard (n - m) % 2 == 0, m <= n else { return 0.0 }
        
        var result = 0.0
        let upperLimit = (n - m) / 2
        
        for k in 0...upperLimit {
            let numerator = calculateFactorial(n - k)
            let denominator = calculateFactorial(k) * calculateFactorial((n + m) / 2 - k) * calculateFactorial((n - m) / 2 - k)
            let coefficient = pow(-1.0, Double(k)) * numerator / denominator
            result += coefficient * pow(rho, Double(n - 2 * k))
        }
        return result
    }
    
    /// Calculates factorial using iterative approach to avoid recursion limits
    private func calculateFactorial(_ n: Int) -> Double {
        guard n >= 0 else { return 0 }
        guard n > 1 else { return 1 }
        
        var result: Double = 1
        for i in 2...n {
            result *= Double(i)
        }
        return result
    }
    
    /// Applies heatmap color overlay to the context
    private func applyHeatmapOverlay(context: CGContext, pixelData: [[Double]], size: CGSize, alpha: CGFloat) {
        let width = Int(size.width)
        let height = Int(size.height)
        
        // Create a bitmap context for efficient pixel drawing
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixelBuffer = [UInt8](repeating: 0, count: height * bytesPerRow)
        
        // Fill the pixel buffer
        for y in 0..<height {
            for x in 0..<width {
                let value = pixelData[y][x]
                if value > 0 {
                    let color = heatmapColor(for: value)
                    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alphaComponent: CGFloat = 0
                    color.getRed(&red, green: &green, blue: &blue, alpha: &alphaComponent)
                    
                    let pixelIndex = (y * width + x) * bytesPerPixel
                    pixelBuffer[pixelIndex] = UInt8(red * 255)     // Red
                    pixelBuffer[pixelIndex + 1] = UInt8(green * 255) // Green
                    pixelBuffer[pixelIndex + 2] = UInt8(blue * 255)  // Blue
                    pixelBuffer[pixelIndex + 3] = UInt8(alpha * 255) // Alpha
                }
            }
        }
        
        // Create CGImage from pixel buffer and draw it
        if let dataProvider = CGDataProvider(data: Data(pixelBuffer) as CFData),
           let cgImage = CGImage(width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bitsPerPixel: 32,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                                provider: dataProvider,
                                decode: nil,
                                shouldInterpolate: false,
                                intent: .defaultIntent) {
            context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// Converts normalized value to heatmap color
    private func heatmapColor(for value: Double) -> UIColor {
        // Clamp value between 0 and 1
        let clampedValue = max(0, min(1, value))
        
        // Create color gradient: Blue (low) -> Green -> Yellow -> Red (high)
        if clampedValue < 0.25 {
            // Blue to Cyan
            let t = clampedValue * 4
            return UIColor(red: 0, green: CGFloat(t), blue: 1, alpha: 1)
        } else if clampedValue < 0.5 {
            // Cyan to Green
            let t = (clampedValue - 0.25) * 4
            return UIColor(red: 0, green: 1, blue: CGFloat(1 - t), alpha: 1)
        } else if clampedValue < 0.75 {
            // Green to Yellow
            let t = (clampedValue - 0.5) * 4
            return UIColor(red: CGFloat(t), green: 1, blue: 0, alpha: 1)
        } else {
            // Yellow to Red
            let t = (clampedValue - 0.75) * 4
            return UIColor(red: 1, green: CGFloat(1 - t), blue: 0, alpha: 1)
        }
    }
    
    /// Draws circle boundary with customizable appearance
    private func drawCircleBoundary(context: CGContext, center: CGPoint, radius: Double, color: UIColor = UIColor.black, lineWidth: CGFloat = 2.0) {
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)
        context.addEllipse(in: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        context.strokePath()
    }
    
    /// Helper to calculate aspect fit rectangle
    private func aspectFitRect(for imageSize: CGSize, in bounds: CGRect) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let boundsAspect = bounds.width / bounds.height
        
        let scaleFactor: CGFloat
        if imageAspect > boundsAspect {
            scaleFactor = bounds.width / imageSize.width
        } else {
            scaleFactor = bounds.height / imageSize.height
        }
        
        let scaledSize = CGSize(
            width: imageSize.width * scaleFactor,
            height: imageSize.height * scaleFactor
        )
        
        let origin = CGPoint(
            x: bounds.midX - scaledSize.width / 2,
            y: bounds.midY - scaledSize.height / 2
        )
        
        return CGRect(origin: origin, size: scaledSize)
    }
}

// MARK: - Helper Extensions
extension Double {
    var squared: Double { self * self }
}

// MARK: - Usage Examples
extension PatientDetailView {
    
    /// Generate heatmap overlaid on original image with proper radius
    func generateOverlayHeatmap() -> UIImage? {
        return generateZernikeHeatmap(in: self.image, overlayOnOriginal: true)
    }
    
    /// Generate standalone heatmap on white background with proper radius
    func generateStandaloneHeatmap() -> UIImage? {
        return generateZernikeHeatmap(in: self.image, overlayOnOriginal: false)
    }
    
    /// Generate heatmap at a specific size while maintaining proper scaling
    func generateScaledHeatmap(size: CGSize, overlay: Bool = false) -> UIImage? {
        return generateZernikeHeatmap(in: self.image, overlayOnOriginal: overlay, imageSize: size)
    }
}
