import SwiftUI
import CoreGraphics
import SwiftData

struct PatientDetailView: View {
    // MARK: DATA INPUT
    let patient: Patient
    let image: UIImage
    let eyeType: EyeType
    let modelContext: ModelContext
    private var eyeLabel: String {
        return eyeType.displayName
    }
    
    // MARK: DATA OUTPUT
    @State internal var redPixelHits: [Int: [(x: Int, y: Int)]] = [:]
    @State internal var ringCenters: [Int: [(radius: Double, x: Double, y: Double)]] = [:]
    @State internal var zernikeCoefficients: [Double] = []
    @State internal var zernikeModes: [(n: Int, m: Int)] = []
    @State internal var radiusHeightAtAngle: RadiusHeightAtAngleData = [:]
    
    @State private var selectedRadiusIndex: Int? = nil
    @State private var targetAngle: Int = 0
    
    // MARK: IMAGE DATA (OUTPUT)
    @State internal var processedImage: UIImage?
    @State internal var heatmapImage: UIImage?
    
    // MARK: Adjdustabl Variables
    /// "If you cant make it percise, make it adjustable"
    @State internal var numSamples: Int = 500
    @State internal var numAngles: Int = 360
    @State internal var threshold: Double = 0.5
    @State internal var slopeCoef: Double = 1.0
    @State internal var referanceDistance: Double = 5.0
    
    // MARK: Navigation Callbacks
    var onBacktoCamera: ((EyeType?) -> Void)?
    var onBacktoDash: (() -> Void)? = nil
    var onDataSaved: (() -> Void)?

    // MARK: Zoom States
    /// TODO: Clean These up, Fucking hate them here
    @State internal var currentZoom: CGFloat = 0
    @State internal var totalZoom: CGFloat = 1
    @State internal var initialZoom: CGFloat = 1
    @State internal var offset: CGSize = .zero
    @State internal var currentOffset: CGSize = .zero

    // MARK: Graph and Image Picker States
    @State private var graphSelection = "Zernike Coefficients"
    let graphOptions = ["Zernike Coefficients", "Height"]
    @State internal var imageSelection = "Point"
    let imageOptions = ["Point", "Zernike", "3D", "Initial"]
    
    // MARK: Processing States
    @State internal var isGeneratingZernike: Bool = false
    @State internal var isProcessing: Bool = false
    @State internal var showPointEditor: Bool = false
    
    // MARK: Alert States
    @State private var showEyeCaptureAlert: Bool = false
    @State private var oppositeEyeType: EyeType? // Store the opposite eye type for navigation

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                ImageView
                
                HStack {
                    Picker("Select a Image", selection: $imageSelection
                        .animation(.easeInOut(duration: 0.1))
                    ) {
                        ForEach(imageOptions, id: \.self) { x in Text(x) }
                    }
                    .pickerStyle(.palette)
                    .padding(.leading, 18)
                                        
                    Button(action: {
                        processImageAndZernikeMap()
                    }) {
                        Text("Re-scan")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .disabled(isProcessing)
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .scaleEffect(1.1)
                    .padding(.trailing, 22)
                    .opacity(0.8)
                }
                if !isProcessing {
                    HStack {
                        DataQualityView(ringCenters: ringCenters)
                            .padding(.leading, 16)
                        
                        AngleScrollView(ringCenters: ringCenters)
                    }
                    .padding(.bottom, 8)
                } else {
                    HStack {
                        Text("Loading")
                    }
                    .padding(.bottom, 8)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Patient Data")
                        .font(.title.bold())
                        .padding(.bottom, 8)
                    
                    Picker("Select a Graph", selection: $graphSelection
                        .animation(.bouncy)
                    ) {
                        ForEach(graphOptions, id: \.self) { x in Text(x) }
                    }.pickerStyle(.palette)
                    
                    VStack(alignment: .leading) {
                        if graphSelection == "Zernike Coefficients" && !zernikeCoefficients.isEmpty {
                            ZernikeCoefBarChartView(
                                coefficients: zernikeCoefficients,
                                modes: zernikeModes
                            )
                        }
                        if graphSelection == "Height" {
                            HeightGraph(
                                radiusHeightAtAngle: radiusHeightAtAngle,
                                targetAngle: $targetAngle,
                                rawSelectedIndex: $selectedRadiusIndex
                            )
                            .frame(height: 120)
                            .padding(.bottom, 10)
                            .padding(.top, 18)
                            .padding(.vertical)
                            
                            HStack {
                                Slider(value: Binding(
                                    get: { Double(targetAngle) },
                                    set: { targetAngle = Int($0.rounded()) }
                                ), in: 0...359, step: 1)
                                .padding(.top)
                                .opacity(0.7)
                                
                                Text("\(targetAngle)°")
                                    .font(.title2)
                                    .padding(.top)
                                    .padding(.trailing)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.vertical)
                
                Divider()
            }
            .onAppear {
                processImageAndZernikeMap()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveDataToPatient()
                    }
                }
            }
            .alert(isPresented: $showEyeCaptureAlert) {
                let otherEye = oppositeEyeType?.displayName ?? "other eye"
                let title = patient.eyeData?.leftEyeImages != nil && patient.eyeData?.rightEyeImages != nil ?
                    "Override \(otherEye) Image?" : "Capture \(otherEye) Image?"
                let message = patient.eyeData?.leftEyeImages != nil && patient.eyeData?.rightEyeImages != nil ?
                    "An image for the \(otherEye) already exists. Do you want to override it?" :
                    "Would you like to capture an image for the \(otherEye)?"
                return Alert(
                    title: Text(title),
                    message: Text(message),
                    primaryButton: .default(Text("Yes")) {
                        // Save current data and navigate back to CameraViewController
                        do {
                            try modelContext.save()
                            onBacktoCamera?(oppositeEyeType)
                        } catch {
                            print("Failed to save patient data: \(error)")
                        }
                    },
                    secondaryButton: .cancel(Text("No")) {
                        // Save and go back to dashboard
                        do {
                            try modelContext.save()
                            onBacktoDash?()
                        } catch {
                            print("Failed to save patient data: \(error)")
                        }
                    }
                )
            }
        }
    }
    
    private func saveDataToPatient() {
        // Ensure patient has eyeData
        if patient.eyeData == nil {
            patient.eyeData = EyeData()
        }
        
        guard let eyeData = patient.eyeData else { return }
        
        // Convert images to Data
        let originalImageData = image.jpegData(compressionQuality: 0.8)
        let heatmapImageData = heatmapImage?.jpegData(compressionQuality: 0.8)
        let processedImageData = processedImage?.jpegData(compressionQuality: 0.8)
        
        switch eyeType {
        case .left:
            // Create or update left eye image store
            if eyeData.leftEyeImages == nil {
                eyeData.leftEyeImages = ImageStore(eyeType: .left)
            }
            eyeData.leftEyeImages?.original = originalImageData
            eyeData.leftEyeImages?.heatmap = heatmapImageData
            eyeData.leftEyeImages?.lensFit = processedImageData
            eyeData.leftEyeTimestamp = Date()
            
        case .right:
            // Create or update right eye image store
            if eyeData.rightEyeImages == nil {
                eyeData.rightEyeImages = ImageStore(eyeType: .right)
            }
            eyeData.rightEyeImages?.original = originalImageData
            eyeData.rightEyeImages?.heatmap = heatmapImageData
            eyeData.rightEyeImages?.lensFit = processedImageData
            eyeData.rightEyeTimestamp = Date()
        }
        
        // Check if both eye images are present
        oppositeEyeType = eyeType == .left ? .right : .left
        if eyeData.leftEyeImages == nil || eyeData.rightEyeImages == nil {
            showEyeCaptureAlert = true
        } else {
            // If both images exist, still show alert to ask about overriding
            showEyeCaptureAlert = true
        }
        
        onDataSaved?()
    }
}

#Preview {
    PatientDetailView(
        patient: Patient(firstName: "John Doe", lastName: "Smith"),
        image: UIImage(named: "output2")!,
        eyeType: EyeType(rawValue: "Left Eye")!,
        modelContext: ModelContext(try! ModelContainer(for: Patient.self))
    )
}
