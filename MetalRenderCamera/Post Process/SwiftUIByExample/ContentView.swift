import SwiftUI
import CoreGraphics

struct ContentView: View {
    @State private var strength = 3.0
    @State private var processedImage: UIImage?
    @State private var redPixelHits: [Int: [(x: Int, y: Int)]] = [:]
    
    var body: some View {
        VStack {
            if let processedImage = processedImage {
                Image(uiImage: processedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image("output")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .onAppear {
                        processImage()
                    }
            }
            
            Button("Scan for Red Pixels") {
                processImage()
            }
            .padding()
            
            // Display hit count fodatar debugging
            Text("Red pixel hits found: \(redPixelHits.values.flatMap { $0 }.count)")
                .padding()
            
            // Show some example hits
            if !redPixelHits.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(redPixelHits.keys.sorted().prefix(10)), id: \.self) { angle in
                            if let hits = redPixelHits[angle], !hits.isEmpty {
                                Text("Angle \(angle)°: \(hits.count) hits")
                                    .font(.caption)
                                ForEach(Array(hits.enumerated().prefix(3)), id: \.offset) { _, hit in
                                    Text("  • (\(hit.x), \(hit.y))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
    }
    
    private func processImage() {
        guard let uiImage = UIImage(named: "output") else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let (resultImage, hits) = self.scanForRedPixels(in: uiImage)
            DispatchQueue.main.async {
                self.processedImage = resultImage
                self.redPixelHits = hits
                print("Red pixel detection complete. Found hits at \(hits.keys.count) angles")
            }
        }
    }
    
    private func scanForRedPixels(in image: UIImage) -> (UIImage, [Int: [(x: Int, y: Int)]]) {
        let size = image.size
        let centerX = size.width / 2
        let centerY = (size.height / 2) + 10
        let maxRadius = min(centerX, centerY) * 0.6
        
        // Create graphics context
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return (image, [:]) }
        
        // Draw original image
        image.draw(at: .zero)
        
        // Get pixel data
        guard let cgImage = image.cgImage,
              let pixelData = getPixelData(from: cgImage) else { return (image, [:]) }
        
        let width = Int(size.width)
        let height = Int(size.height)
        
        var redPixelHits: [Int: [(x: Int, y: Int)]] = [:]
        
        // Scan every degree from 0 to 359
        for angle in 0..<360 {
            let radians = Double(angle) * .pi / 180
            var hitsForThisAngle: [(x: Int, y: Int)] = []
            
            // Sample pixels along the radial line from center outward
            for radius in stride(from: 1, to: Double(maxRadius), by: 1) {
                let x = centerX + radius * cos(radians)
                let y = centerY + radius * sin(radians)
                
                let pixelX = Int(round(x))
                let pixelY = Int(round(y))
                
                // Check bounds
                if pixelX >= 0 && pixelX < width && pixelY >= 0 && pixelY < height {
                    let pixelIndex = (pixelY * width + pixelX) * 4
                    let r = pixelData[pixelIndex]
                    let g = pixelData[pixelIndex + 1]
                    let b = pixelData[pixelIndex + 2]
                    let a = pixelData[pixelIndex + 3]
                    
                    // Check if pixel is red (high red, low green and blue)
                    if isRedPixel(r: r, g: g, b: b, a: a) {
                        hitsForThisAngle.append((x: pixelX, y: pixelY))
                        
                        // Draw a small circle at the hit location for visualization
                        context.setFillColor(UIColor.yellow.cgColor)
                        let hitCircle = CGRect(x: CGFloat(pixelX) - 2, y: CGFloat(pixelY) - 2, width: 4, height: 4)
                        context.fillEllipse(in: hitCircle)
                    }
                }
            }
            
            // Only store angles that have hits
            if !hitsForThisAngle.isEmpty {
                redPixelHits[angle] = hitsForThisAngle
            }
            
            // Draw the scan line for visualization (optional)
            context.setStrokeColor(UIColor.blue.withAlphaComponent(0.3).cgColor)
            context.setLineWidth(1.0)
            context.beginPath()
            context.move(to: CGPoint(x: centerX, y: centerY))
            let endX = centerX + maxRadius * cos(radians)
            let endY = centerY + maxRadius * sin(radians)
            context.addLine(to: CGPoint(x: endX, y: endY))
            context.strokePath()
        }
        
        // Mark the center
        context.setFillColor(UIColor.green.cgColor)
        let centerCircle = CGRect(x: centerX - 5, y: centerY - 5, width: 10, height: 10)
        context.fillEllipse(in: centerCircle)
        
        guard let resultImage = UIGraphicsGetImageFromCurrentImageContext() else { return (image, redPixelHits) }
        return (resultImage, redPixelHits)
    }
    
    private func isRedPixel(r: UInt8, g: UInt8, b: UInt8, a: UInt8) -> Bool {
        // Define what constitutes a "red" pixel
        // You can adjust these thresholds based on your specific image
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
    
    private func getPixelData(from cgImage: CGImage) -> [UInt8]? {
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
}

// Extension to help with pixel manipulation and data access
extension ContentView {
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
    
    // Function to get all red pixel hits
    func getAllRedPixelHits() -> [Int: [(x: Int, y: Int)]] {
        return redPixelHits
    }
    
    // Function to get red pixel hits for a specific angle
    func getRedPixelHits(forAngle angle: Int) -> [(x: Int, y: Int)]? {
        return redPixelHits[angle]
    }
    
    // Function to get all red pixel coordinates in a flat array
    func getAllRedPixelCoordinates() -> [(x: Int, y: Int, angle: Int)] {
        var allCoords: [(x: Int, y: Int, angle: Int)] = []
        for (angle, hits) in redPixelHits {
            for hit in hits {
                allCoords.append((x: hit.x, y: hit.y, angle: angle))
            }
        }
        return allCoords.sorted { $0.angle < $1.angle }
    }
    
    // Function to export data as JSON string
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
}

#Preview {
    ContentView()
}
