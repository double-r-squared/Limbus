import SwiftUI
import CoreGraphics

struct PatientDetailView: View {
    let patient: Patient
    let image: UIImage
    
    @State private var currentZoom: CGFloat = 0
    @State private var totalZoom: CGFloat = 1
    @State private var initialZoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var currentOffset: CGSize = .zero
    @State private var processedImage: UIImage?
    @State private var redPixelHits: [Int: [(x: Int, y: Int)]] = [:]
    @State private var ringCenters: [Int: [(radius: Double, x: Double, y: Double)]] = [:]
    @State private var isProcessing: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Original Zoomable Image Frame
                VStack(alignment: .leading, spacing: 8) {
                    Text("Original Image")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Square image container
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .scaleEffect((currentZoom + totalZoom) * initialZoom)
                        .offset(x: offset.width + currentOffset.width, y: offset.height + currentOffset.height)
                        .gesture(
                            SimultaneousGesture(
                                // Zoom gesture
                                MagnificationGesture()
                                    .onChanged { value in
                                        currentZoom = value - 1
                                    }
                                    .onEnded { value in
                                        totalZoom += currentZoom
                                        totalZoom = min(max(totalZoom, 0.5), 4) // Limit zoom 0.5x-4x
                                        currentZoom = 0
                                        
                                        // Reset offset if zoomed out too much
                                        if totalZoom <= 1 {
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                offset = .zero
                                            }
                                        }
                                    },
                                
                                // Pan gesture (only active when zoomed in)
                                DragGesture()
                                    .onChanged { value in
                                        if totalZoom > 1 {
                                            currentOffset = value.translation
                                        }
                                    }
                                    .onEnded { value in
                                        if totalZoom > 1 {
                                            offset.width += value.translation.width
                                            offset.height += value.translation.height
                                            currentOffset = .zero
                                            
                                            // Constrain offset to prevent image from going too far
                                            let maxOffset: CGFloat = 100 * totalZoom
                                            offset.width = min(max(offset.width, -maxOffset), maxOffset)
                                            offset.height = min(max(offset.height, -maxOffset), maxOffset)
                                        }
                                    }
                            )
                        )
                        .frame(width: 400, height: 400) // Square frame
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .animation(.easeOut(duration: 0.1), value: totalZoom)
                        .onAppear {
                            // Calculate initial zoom to match container width
                            let imageSize = image.size
                            let containerSize: CGFloat = 400
                            let scaleToFitWidth = containerSize / imageSize.width
                            initialZoom = scaleToFitWidth * 4
                            
                            // Auto-process the image when view appears
                            processImage()
                        }
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity) // Centers the square
                    
                    // Zoom controls
                    HStack {
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.3)) {
                                totalZoom = max(totalZoom - 0.5, 0.5)
                                if totalZoom <= 1 {
                                    offset = .zero
                                }
                            }
                        }) {
                            Image(systemName: "minus.magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(totalZoom <= 0.5)
                        
                        Text("\(Int(totalZoom * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 50)
                        
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.3)) {
                                totalZoom = min(totalZoom + 0.5, 4)
                            }
                        }) {
                            Image(systemName: "plus.magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(totalZoom >= 4)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.3)) {
                                totalZoom = 1
                                offset = .zero
                            }
                        }) {
                            Text("Reset")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // Processed Image Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Processed Image")
                            .font(.headline)
                        
                        Spacer()
                        
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Button("Re-scan") {
                                processImage()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Processed Image Display
                    if let processedImage = processedImage {
                        Image(uiImage: processedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 400, height: 400)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(width: 400, height: 400)
                            .overlay(
                                VStack {
                                    if isProcessing {
                                        ProgressView()
                                        Text("Processing...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.top, 8)
                                    } else {
                                        Text("No processed image")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity)
                    }
                    
                    // Red Pixel Data Summary
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Data Points: \(ringCenters.values.flatMap { $0 }.count)")
                            .font(.caption)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<12) { i in
                                    let angle = i * 30
                                    if let rings = ringCenters[angle], !rings.isEmpty {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Angle \(angle)°")
                                                .font(.caption2)
                                                .bold()
                                            Text("\(rings.count) rings")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(8)
                                        .background(Color(.tertiarySystemBackground))
                                        .cornerRadius(6)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 8)
                }
                
                // Patient Info Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Patient Data")
                        .font(.title.bold())
                        .padding(.bottom, 8)
                    
                    InfoRow(label: "Name", value: "\(patient.firstName) \(patient.lastName)")
                    if !ringCenters.isEmpty {
                        InfoRow(label: "Data Points", value: "\(ringCenters.values.flatMap { $0 }.count)")
                        InfoRow(label: "Angles Detected", value: "\(ringCenters.keys.count)")
                    }
                    // Add more patient fields as needed
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Processing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    // MARK: - Image Processing Functions
    
    private func processImage() {
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let (resultImage, hits, centers) = self.analyzeRingsWithSubpixelAccuracy(in: self.image)
            
            DispatchQueue.main.async {
                self.processedImage = resultImage
                self.redPixelHits = hits
                self.ringCenters = centers
                self.isProcessing = false
                print("Ring analysis complete. Found \(centers.values.flatMap { $0 }.count) ring centers at \(centers.keys.count) angles")
            }
        }
    }
    
    private func analyzeRingsWithSubpixelAccuracy(in image: UIImage) -> (UIImage, [Int: [(x: Int, y: Int)]], [Int: [(radius: Double, x: Double, y: Double)]]) {
        let size = image.size
        let centerX = size.width / 2
        let centerY = (size.height / 2) + 10
        let maxRadius = min(centerX, centerY) * 0.6
        
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
        
        // Use more angles for better accuracy (similar to Python's 720)
        let numAngles = 720
        let numSamples = 800
        let threshold: Double = 0.5
        
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
    
    private func bilinearInterpolate(pixelData: [UInt8], width: Int, height: Int, x: Double, y: Double) -> Double {
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
    
    private func isRedPixelDouble(r: Double, g: Double, b: Double, a: Double) -> Bool {
        let colorThreshold: Double = 150.0
        let alphaThreshold: Double = 128.0
        
        return r >= colorThreshold &&
               g >= colorThreshold &&
               b >= colorThreshold &&
               a >= alphaThreshold
    }

    
    private func groupConsecutiveHits(hitRadii: [Double], hitIndices: [Int], angle: Double, centerX: Double, centerY: Double) -> [(radius: Double, x: Double, y: Double)] {
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
    
    private func drawVisualization(context: CGContext, ringCenters: [Int: [(radius: Double, x: Double, y: Double)]], centerX: Double, centerY: Double, maxRadius: Double) {
        // Draw ring centers as blue dots
        context.setFillColor(UIColor.blue.cgColor)
        for (_, rings) in ringCenters {
            for ring in rings {
                let ringRect = CGRect(x: ring.x - 3, y: ring.y - 3, width: 6, height: 6)
                context.fillEllipse(in: ringRect)
            }
        }
        
        // Draw some scan lines for reference (reduced for clarity)
        context.setStrokeColor(UIColor.yellow.cgColor)
        context.setLineWidth(0.8)
        
        for angle in stride(from: 0, to: 360, by: 10) {
            let radians = Double(angle) * .pi / 180
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
    }
    
    private func isRedPixel(r: UInt8, g: UInt8, b: UInt8, a: UInt8) -> Bool {
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

// MARK: - Extensions

extension PatientDetailView {
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
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
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
