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
    
    /// Generates a 2D Zernike polynomial heatmap
    /// - Parameters:
    ///   - overlayOnOriginal: If true, overlays on original image; if false, uses white background
    ///   - imageSize: Size of the output image
    ///   - radius: Circle radius for the pupil area
    /// - Returns: UIImage with the Zernike heatmap
    func generateZernikeHeatmap(in image: UIImage, overlayOnOriginal: Bool = false, imageSize: CGSize = CGSize(width: 400, height: 400), radius: Double = 150) -> UIImage {
        
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        
        let resultImage = renderer.image { context in
            let cgContext = context.cgContext
            
            // Background setup
            if overlayOnOriginal {
                // Draw original image as background
                if let originalImage = processedImage {
                    let aspectFitRect = aspectFitRect(for: originalImage.size, in: CGRect(origin: .zero, size: imageSize))
                    originalImage.draw(in: aspectFitRect)
                }
            } else {
                // White background
                cgContext.setFillColor(UIColor.white.cgColor)
                cgContext.fill(CGRect(origin: .zero, size: imageSize))
            }
            
            // Calculate center
            let centerX = imageSize.width / 2
            let centerY = imageSize.height / 2
            
            // Create heatmap
            // MARK: Needs to Fit the AOI
            
            let pixelData = generateZernikePixelData(
                width: Int(imageSize.width),
                height: Int(imageSize.height),
                centerX: centerX,
                centerY: centerY,
                radius: radius
            )
            
            // Apply heatmap overlay
            applyHeatmapOverlay(
                context: cgContext,
                pixelData: pixelData,
                size: imageSize,
                alpha: overlayOnOriginal ? 0.7 : 1.0
            )
            
            // Draw circle boundary
            drawCircleBoundary(context: cgContext, center: CGPoint(x: centerX, y: centerY), radius: radius)
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
                    if pixelData[y][x] != 0.0 || (Double(x - Int(centerX)).squared + Double(y - Int(centerY)).squared) <= radius.squared {
                        pixelData[y][x] = (pixelData[y][x] - minValue) / range
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
        
        for y in 0..<height {
            for x in 0..<width {
                let value = pixelData[y][x]
                if value > 0 {
                    let color = heatmapColor(for: value).withAlphaComponent(alpha)
                    context.setFillColor(color.cgColor)
                    context.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
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
    
    /// Draws circle boundary
    private func drawCircleBoundary(context: CGContext, center: CGPoint, radius: Double) {
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(2.0)
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
//extension PatientDetailView {
//    
//    /// Generate heatmap overlaid on original image
//    func generateOverlayHeatmap() -> UIImage? {
//        return generateZernikeHeatmap(in: self.image, overlayOnOriginal: true)
//    }
//    
//    /// Generate standalone heatmap on white background
//    func generateStandaloneHeatmap() -> UIImage? {
//        return self.generateZernikeHeatmap(in: self.image, overlayOnOriginal: false)
//    }
//}
