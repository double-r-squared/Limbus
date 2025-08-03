//
//  PatientDetailExtension.swift
//  Metal Camera
//
//  Created by Nate  on 7/19/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//

import SwiftUI
import CoreGraphics
import Charts

extension PatientDetailView {
    
    func processImageAndZernikeMap() {
        isProcessing = true
        isGeneratingZernike = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let (processedImage, redPixelHits, ringCenters) = self.analyzeRingsWithSubpixelAccuracy(in: self.image)
            self.redPixelHits = redPixelHits
            self.ringCenters = ringCenters
            print("Ring analysis complete. Found \(ringCenters.values.flatMap { $0 }.count) ring centers at \(ringCenters.keys.count) angles")

            self.analyzePolarData()
            let heatmapImage = self.generateZernikeHeatmap(in: self.image, overlayOnOriginal: true)
            print("Heat map Generated!")
            
            DispatchQueue.main.async {
                self.processedImage = processedImage
                self.heatmapImage = heatmapImage
                self.isProcessing = false
                self.isGeneratingZernike = false
            }
        }
    }
    
    func getPixelColor(at point: CGPoint, in image: UIImage) -> UIColor? {
        guard let cgImage = image.cgImage,
              let pixelData = getPixelData(from: cgImage) else { return nil }
        
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let x = Int(point.x)
        let y = Int(point.y)
        
        guard x >= 0 && x < width && y >= 0 && y < height else { return nil }
        
        let pixelIndex = (y * width + x) * 4
        let r = CGFloat(pixelData[pixelIndex]) / 255.0
        let g = CGFloat(pixelData[pixelIndex + 1]) / 255.0
        let b = CGFloat(pixelData[pixelIndex + 2]) / 255.0
        let a = CGFloat(pixelData[pixelIndex + 3]) / 255.0
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    // Function to get all ring centers
    func getAllRingCenters() -> [Int: [(radius: Double, x: Double, y: Double)]] {
        return ringCenters
    }
    
    // Function to get ring centers for a specific angle
    func getRingCenters(forAngle angle: Int) -> [(radius: Double, x: Double, y: Double)]? {
        return ringCenters[angle]
    }
    
    // Function to get all ring center coordinates in a flat array
    func getAllRingCenterCoordinates() -> [(x: Double, y: Double, radius: Double, angle: Int)] {
        var allCenters: [(x: Double, y: Double, radius: Double, angle: Int)] = []
        for (angle, rings) in ringCenters {
            for ring in rings {
                allCenters.append((x: ring.x, y: ring.y, radius: ring.radius, angle: angle))
            }
        }
        return allCenters.sorted { $0.angle < $1.angle }
    }
    
    // Function to export ring center data as JSON string
    func exportRingCenterData() -> String {
        let jsonData = ringCenters.mapValues { rings in
            rings.map { ["x": $0.x, "y": $0.y, "radius": $0.radius] }
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted)
            return String(data: data, encoding: .utf8) ?? "Error encoding JSON"
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
    
    // Legacy functions for backward compatibility
    func getAllRedPixelHits() -> [Int: [(x: Int, y: Int)]] {
        return redPixelHits
    }
    
    func getRedPixelHits(forAngle angle: Int) -> [(x: Int, y: Int)]? {
        return redPixelHits[angle]
    }
    
    func getAllRedPixelCoordinates() -> [(x: Int, y: Int, angle: Int)] {
        var allCoords: [(x: Int, y: Int, angle: Int)] = []
        for (angle, hits) in redPixelHits {
            for hit in hits {
                allCoords.append((x: hit.x, y: hit.y, angle: angle))
            }
        }
        return allCoords.sorted { $0.angle < $1.angle }
    }
    
    func exportRedPixelData() -> String {
        let jsonData = redPixelHits.mapValues { hits in
            hits.map { ["x": $0.x, "y": $0.y] }
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted)
            return String(data: data, encoding: .utf8) ?? "Error encoding JSON"
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
    
    func analyzeRingsWithSubpixelAccuracy(in image: UIImage) -> (UIImage, [Int: [(x: Int, y: Int)]], [Int: [(radius: Double, x: Double, y: Double)]]) {
        let size = image.size
        let centerX = size.width / 2
        let centerY = (size.height / 2)
        let maxRadius = min(centerX, centerY) * 0.9
        
        // Create graphics context
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return (image, [:], [:]) }
        
        // Draw original image
        image.draw(at: .zero)
        
        // Get pixel data
        guard let cgImage = image.cgImage,
              let pixelData = getPixelData(from: cgImage) else { return (image, [:], [:]) }
        
        let width = Int(size.width)
        let height = Int(size.height)
        
        var redPixelHits: [Int: [(x: Int, y: Int)]] = [:]
        var ringCenters: [Int: [(radius: Double, x: Double, y: Double)]] = [:]
        
        for angleIndex in 0..<numAngles {
            let angle = Double(angleIndex) * 2.0 * .pi / Double(numAngles)
            let angleDegrees = Int(Double(angleIndex) * 360.0 / Double(numAngles))
            
            // Generate subpixel radii and coordinates
            var hitRadii: [Double] = []
            var hitIndices: [Int] = []
            var allHits: [(x: Int, y: Int)] = []
            
            for sampleIndex in 0..<numSamples {
                let radius = Double(sampleIndex) * maxRadius / Double(numSamples)
                let x = centerX + radius * cos(angle)
                let y = centerY + radius * sin(angle)
                
                // Bilinear interpolation for subpixel accuracy
                let intensity = bilinearInterpolate(pixelData: pixelData,
                                                    width: width,
                                                    height: height,
                                                    x: x, y: y)
                
                if intensity > threshold {
                    hitRadii.append(radius)
                    hitIndices.append(sampleIndex)
                    allHits.append((x: Int(round(x)), y: Int(round(y))))
                }
            }
            
            // Group consecutive hits into rings
            let groupedRings = groupConsecutiveHits(hitRadii: hitRadii, hitIndices: hitIndices, angle: angle, centerX: centerX, centerY: centerY)
            
            if !allHits.isEmpty {
                redPixelHits[angleDegrees] = allHits
            }
            
            if !groupedRings.isEmpty {
                ringCenters[angleDegrees] = groupedRings
            }
        }
        
        // Draw visualization
        drawVisualization(context: context,
                          ringCenters: ringCenters,
                          centerX: centerX,
                          centerY: centerY,
                          maxRadius: maxRadius)
        
        guard let resultImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return (image, redPixelHits, ringCenters)
        }
        return (resultImage, redPixelHits, ringCenters)
    }
    
    func bilinearInterpolate(pixelData: [UInt8], width: Int, height: Int, x: Double, y: Double) -> Double {
        let x0 = Int(floor(x))
        let y0 = Int(floor(y))
        let x1 = min(x0 + 1, width - 1)
        let y1 = min(y0 + 1, height - 1)
        
        // Check bounds
        guard x0 >= 0 && y0 >= 0 && x1 < width && y1 < height else { return 0.0 }
        
        let dx = x - Double(x0)
        let dy = y - Double(y0)
        
        // Get pixel values at corners
        let getPixelIntensity = { (px: Int, py: Int) -> Double in
            let pixelIndex = (py * width + px) * 4
            let r = Double(pixelData[pixelIndex])
            let g = Double(pixelData[pixelIndex + 1])
            let b = Double(pixelData[pixelIndex + 2])
            let a = Double(pixelData[pixelIndex + 3])
            
            // Check if it's a red pixel and return normalized intensity
            if self.isRedPixelDouble(r: r, g: g, b: b, a: a) {
                return r / 255.0
            }
            return 0.0
        }
        
        let i00 = getPixelIntensity(x0, y0)
        let i10 = getPixelIntensity(x1, y0)
        let i01 = getPixelIntensity(x0, y1)
        let i11 = getPixelIntensity(x1, y1)
        
        // Bilinear interpolation
        let i0 = i00 * (1.0 - dx) + i10 * dx
        let i1 = i01 * (1.0 - dx) + i11 * dx
        return i0 * (1.0 - dy) + i1 * dy
    }
    
    func isRedPixelDouble(r: Double, g: Double, b: Double, a: Double) -> Bool {
        let colorThreshold: Double = 150.0
        let alphaThreshold: Double = 128.0
        
        return r >= colorThreshold &&
        g >= colorThreshold &&
        b >= colorThreshold &&
        a >= alphaThreshold
    }
    
    func groupConsecutiveHits(hitRadii: [Double], hitIndices: [Int], angle: Double, centerX: Double, centerY: Double) -> [(radius: Double, x: Double, y: Double)] {
        guard !hitRadii.isEmpty else { return [] }
        
        var groupedRings: [(radius: Double, x: Double, y: Double)] = []
        var currentGroup: [Double] = [hitRadii[0]]
        
        for i in 1..<hitIndices.count {
            // Check if current hit is consecutive to previous
            if hitIndices[i] == hitIndices[i - 1] + 1 {
                currentGroup.append(hitRadii[i])
            } else {
                // End current group and start new one
                let avgRadius = currentGroup.reduce(0.0, +) / Double(currentGroup.count)
                let centerRingX = centerX + avgRadius * cos(angle)
                let centerRingY = centerY + avgRadius * sin(angle)
                groupedRings.append((radius: avgRadius, x: centerRingX, y: centerRingY))
                currentGroup = [hitRadii[i]]
            }
        }
        
        // Handle final group
        if !currentGroup.isEmpty {
            let avgRadius = currentGroup.reduce(0.0, +) / Double(currentGroup.count)
            let centerRingX = centerX + avgRadius * cos(angle)
            let centerRingY = centerY + avgRadius * sin(angle)
            groupedRings.append((radius: avgRadius, x: centerRingX, y: centerRingY))
        }
        return groupedRings
    }
    
    func drawVisualization(context: CGContext, ringCenters: [Int: [(radius: Double, x: Double, y: Double)]], centerX: Double, centerY: Double, maxRadius: Double) {
        
        // Draw ring centers as blue dots
        context.setFillColor(UIColor.blue.cgColor)
        for (_, rings) in ringCenters {
            for ring in rings {
                let ringRect = CGRect(x: ring.x, y: ring.y, width: 2, height: 2)
                context.fillEllipse(in: ringRect)
            }
        }
        
        // Mark the center
        context.setFillColor(UIColor.green.cgColor)
        let centerCircle = CGRect(x: centerX, y: centerY, width: 3, height: 3)
        context.fillEllipse(in: centerCircle)
    }
    
    func isRedPixel(r: UInt8, g: UInt8, b: UInt8, a: UInt8) -> Bool {
        // Define what constitutes a "red" pixel
        let redThreshold: UInt8 = 100    // Minimum red value
        let greenMaxThreshold: UInt8 = 80  // Maximum green value
        let blueMaxThreshold: UInt8 = 80   // Maximum blue value
        let alphaThreshold: UInt8 = 128    // Minimum alpha (not too transparent)
        
        return r >= redThreshold &&
        g <= greenMaxThreshold &&
        b <= blueMaxThreshold &&
        a >= alphaThreshold &&
        r > g && r > b  // Red should be the dominant color
    }
    
    func getPixelData(from cgImage: CGImage) -> [UInt8]? {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        
        guard let ctx = context else { return nil }
        
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return pixelData
    }
    
    struct InfoRow: View {
        let label: String
        let value: String
        
        var body: some View {
            Divider()
            HStack {
                Text(label)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .font(.body.monospacedDigit())
            }
            .padding(.vertical, 4)
        }
    }
}
