import SwiftUI
import CoreGraphics

struct PatientDetailView: View {
    let patient: Patient
    let image: UIImage
    let eyeType: EyeType
    private var eyeLabel: String {
        return eyeType.displayName
    }
    
    @State internal var currentZoom: CGFloat = 0
    @State internal var totalZoom: CGFloat = 1
    @State internal var initialZoom: CGFloat = 1
    @State internal var offset: CGSize = .zero
    @State internal var currentOffset: CGSize = .zero

    @State internal var redPixelHits: [Int: [(x: Int, y: Int)]] = [:]
    @State internal var ringCenters: [Int: [(radius: Double, x: Double, y: Double)]] = [:]
    
    @State internal var zernikeCoefficients: [Double] = []
    @State internal var zernikeModes: [(n: Int, m: Int)] = []
    
    @State internal var radiusHeightAtAngle: RadiusHeightAtAngleData = [:]
    @State private var selectedRadiusIndex: Int? = nil
    @State private var targetAngle: Int = 0
    
    @State private var graphSelection = "Zernike Coefficients"
    let graphOptions = ["Zernike Coefficients", "Hieght"]
    @State internal var imageSelection = "Point"
    let imageOptions = ["Point", "Zernike", "3D", "Initial"]
    
    @State internal var isGeneratingZernike: Bool = false
    @State internal var isProcessing: Bool = false
    @State internal var showPointEditor: Bool = false
    
    @State internal var processedImage: UIImage?
    @State internal var heatmapImage: UIImage?
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                ImageView
                
                HStack {
                    Picker("Select a Image", selection: $imageSelection
                        .animation(.easeInOut(duration: 0.1))
                    ){
                        ForEach(imageOptions, id:\.self){x  in Text(x)}
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
                    HStack{
                        DataQualityView(ringCenters: ringCenters)
                            .padding(.leading, 16)
                        
                        AngleScrollView(ringCenters: ringCenters)
                        
                    }
                    .padding(.bottom, 8)
                } else {
                    HStack{
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
                    ){
                        ForEach(graphOptions, id:\.self){x  in Text(x)}
                    }.pickerStyle(.palette)
                    
                    VStack(alignment: .leading) {
                        if graphSelection == "Zernike Coefficients" && !zernikeCoefficients.isEmpty {
                            ZernikeCoefBarChartView(
                                coefficients: zernikeCoefficients,
                                modes: zernikeModes
                            )
                        }
                        if graphSelection == "Hieght" {
                            HeightGraph(
                                radiusHeightAtAngle: radiusHeightAtAngle,
                                targetAngle: $targetAngle,
                                rawSelectedIndex: $selectedRadiusIndex
                            )
                            .frame(height: 120)
                            .padding(.bottom, 10)
                            .padding(.top, 18)
                            .padding(.vertical)
                            
                            HStack{
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
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                        // Navigate to Dashboard & Save right/left
                        // Navigate to CameraView Right/Left & Save right/left
                    }
                }
            }
        }
    }
}

#Preview {
    PatientDetailView(patient: Patient(firstName: "John Doe", lastName: "Smith"), image: UIImage(named: "output2")!, eyeType: EyeType(rawValue: "Left Eye")!)
}
