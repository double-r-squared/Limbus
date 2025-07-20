import SwiftUI
import CoreGraphics

struct PatientDetailView: View {
    let patient: Patient
    let image: UIImage
    let eyeType: EyeType

    
    @State private var currentZoom: CGFloat = 0
    @State private var totalZoom: CGFloat = 1
    @State private var initialZoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var currentOffset: CGSize = .zero
    
    @State internal var processedImage: UIImage?
    @State internal var redPixelHits: [Int: [(x: Int, y: Int)]] = [:]
    @State internal var ringCenters: [Int: [(radius: Double, x: Double, y: Double)]] = [:]
    @State internal var isProcessing: Bool = false
    
    @Environment(\.presentationMode) var presentationMode
    
    private var eyeLabel: String {
        return eyeType.displayName
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                if let processedImage = processedImage {
                    Image(uiImage: processedImage)
                        .resizable()
                        .scaledToFill()
                        .scaleEffect((currentZoom + totalZoom) * initialZoom)
                        .offset(x: offset.width + currentOffset.width, y: offset.height + currentOffset.height)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        currentZoom = value - 1
                                    }
                                    .onEnded { value in
                                        totalZoom += currentZoom
                                        totalZoom = min(max(totalZoom, 0.5), 4)
                                        currentZoom = 0
                                        if totalZoom <= 1 {
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                offset = .zero
                                            }
                                        }
                                    },
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
                                            let maxOffset: CGFloat = 100 * totalZoom
                                            offset.width = min(max(offset.width, -maxOffset), maxOffset)
                                            offset.height = min(max(offset.height, -maxOffset), maxOffset)
                                        }
                                    }
                            )
                        )
                        .frame(width: 400, height: 400)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .overlay(
                            VStack {
                                HStack {
                                    Text(eyeLabel)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.leading, 8)
                                    Spacer()
                                    if isProcessing {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .padding(.trailing, 8)
                                    }
                                }
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.6))
                                Spacer()
                            }
                        )
                        .animation(.easeOut(duration: 0.1), value: totalZoom)
                        .onAppear {
                            let imageSize = image.size
                            let containerSize: CGFloat = 400
                            let scaleToFitWidth = containerSize / imageSize.width
                            initialZoom = scaleToFitWidth * 4
                        }
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)
                    
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
                            
                            
                            processImage()
                            
                            // AdjustView
                            
                        }) {
                            Text("Adjust")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            }
                            .disabled(isProcessing)
                        
                        Divider()
                                .frame(height: 20) // Adjust the height as needed
                                .overlay(Color.gray) // Optional: Change the color of the divider

                        Button(action: {
                            processImage()
                        }) {
                            Text("Re-scan")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .disabled(isProcessing)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
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
                                    Button(action: {
                                        processImage()
                                    }) {
                                        Text("Initialize Scan")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 8)
                                            .background(Color(.tertiarySystemBackground))
                                            .cornerRadius(8)
                                    }
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
                
                VStack(alignment: .leading, spacing: 8) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Data Points: \(ringCenters.values.flatMap { $0 }.count)")
                            .font(.caption)
                            .padding(.horizontal)
                        Text("Data Quality: \(ringCenters.values.flatMap { $0 }.count)")
                            .font(.caption)
                            .padding(.horizontal)
                        
                        // MARK: - Data Quality Functions
                        
                        // TODO: qualityOfRingsDetected()
                        // Rings out of hardware number (20)
                        // Average/Median rings detected over all angles
                        
                        // Example: over 360 angles 10/20 = 50%
                        // Weight this number SIGNIFIGANT if less then 15 Rings detected.
                        // 15 rings is not adequate enough to make a proper decison
                        
                        // TODO: qualityOfPointsDetected()
                        // Spread of Rings if rings are too close together specified min, max.
                        // if points fall out of bounds of constant range they are outliers.
                        
                        // Example: # of points out of Bounds - # of points in bounds / Expected # of points
                        // Weight this number SIGNIFIGANT,
                        // because if most points are too close or too far away then data is unuseable
                        
                        // TODO: getDataQuality()
                        // adds qualityOfPointsDetected() and qualityOfRingsDetected(), weighs both coeficients
                        // returns # out of 100%

                        // TODO: cleanData()
                        // remove outliers too close to each other
                        // return data points that are cohesive.
                        // get new data quality #
                        
                    }
                    
                    
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
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Patient Data")
                    .font(.title.bold())
                    .padding(.bottom, 8)
                
                InfoRow(label: "Name", value: "\(patient.firstName) \(patient.lastName)")
                if !ringCenters.isEmpty {
                    InfoRow(label: "Data Points", value: "\(ringCenters.values.flatMap { $0 }.count)")
                    InfoRow(label: "Angles Detected", value: "\(ringCenters.keys.count)")
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
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
}


#Preview {
    PatientDetailView(patient: Patient(firstName: "John Doe", lastName: "Smith"), image: UIImage(named: "output")!, eyeType: EyeType(rawValue: "Left Eye")!)
}
    
