import UIKit
import Metal
import SwiftUI
import SwiftData
import MetalKit

internal class CameraViewController: MTKViewController {
    var session: MetalCameraSession?
    var patient: Patient?
    var eyeType: EyeType? // Pre-selected eye from CameraViewController
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.onFrameCaptured = { [weak self] (texture, brightness) in
            guard let self = self, let patient = self.patient, let eyeType = self.eyeType else { return }
            
            let processVC = ProcessViewController()
            processVC.capturedTexture = texture
            processVC.capturedBrightness = brightness
            processVC.patient = patient
            
            processVC.onSave = { [weak self] patient, image, eyeType, brightness in
                guard let self = self else { return }
                
                // Convert UIImage to Data
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    print("Failed to convert image to data")
                    return
                }
                
                // Update patient's EyeData directly
                do {
                    if patient.eyeData == nil {
                        patient.eyeData = EyeData()
                    }
                    
                    switch eyeType {
                    case .left:
                        patient.eyeData?.leftEyeImages = ImageStore(eyeType: .left, original: imageData)
                        patient.eyeData?.leftEyeScore = Double(brightness)
                        patient.eyeData?.leftEyeTimestamp = Date()
                        print("Saved left eye data for \(patient.firstName)")
                    case .right:
                        patient.eyeData?.rightEyeImages = ImageStore(eyeType: .right, original: imageData)
                        patient.eyeData?.rightEyeScore = Double(brightness)
                        patient.eyeData?.rightEyeTimestamp = Date()
                        print("Saved right eye data for \(patient.firstName)")
                    }
                    
                    // Save to SwiftData
                    try self.modelContext.save()
                    
                    DispatchQueue.main.async {
                        self.navigateToPatientDetail(patient: patient, image: image, eyeType: eyeType)
                    }
                } catch {
                    print("Failed to save patient: \(error)")
                    self.showAlert(message: "Failed to save patient: \(error.localizedDescription)")
                }
            }
            
            self.present(processVC, animated: true)
        }
        
        session = MetalCameraSession(frameOrientation: .portrait, delegate: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("CameraViewController: viewWillAppear called")
        texture = nil
        clearMetalView()
        session?.start()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("CameraViewController: viewDidDisappear called")
        session?.stop()
        texture = nil
        clearMetalView()
    }
    
    private func navigateToPatientDetail(patient: Patient, image: UIImage, eyeType: EyeType) {
        session?.stop()

        let swiftUIView = PatientDetailView(
            patient: patient,
            image: image,
            eyeType: eyeType,
            modelContext: ModelContext(try! ModelContainer(for: Patient.self)),
            onBacktoCamera: { [weak self] newEyeType in
                DispatchQueue.main.async {
                    if let newEyeType = newEyeType {
                        self?.eyeType = newEyeType // Update eyeType for the next capture
                    }
                    self?.navigationController?.popViewController(animated: true)
                }
            },
            onBacktoDash: { [weak self] in
                DispatchQueue.main.async {
                    // Dismiss the entire modal to return to Dashboard
                    self?.dismiss(animated: true)
                }
            }
        )
        
        let hostingVC = UIHostingController(rootView: swiftUIView)
        navigationController?.pushViewController(hostingVC, animated: true)
    }
    
    private func clearMetalView() {
        guard let mtkView = view as? MTKView else { return }
        mtkView.drawableSize = mtkView.bounds.size
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1) // Black background
        guard let drawable = mtkView.currentDrawable,
              let commandBuffer = commandQueue?.makeCommandBuffer() else { return }
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            renderEncoder.endEncoding()
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - MetalCameraSessionDelegate
extension CameraViewController: MetalCameraSessionDelegate {
    func metalCameraSession(_ session: MetalCameraSession, didReceiveFrameAsTextures textures: [MTLTexture], withTimestamp timestamp: Double) {
        print("CameraViewController: Received new frame at timestamp: \(timestamp)")
        self.texture = textures[0]
        DispatchQueue.main.async {
            self.title = "Patient: \(self.patient?.firstName ?? "Unknown")"
        }
    }
    
    func metalCameraSession(_ cameraSession: MetalCameraSession, didUpdateState state: MetalCameraSessionState, error: MetalCameraSessionError?) {
        print("CameraViewController: Session state changed to \(state), error: \(error?.localizedDescription ?? "None")")
        switch state {
        case .error where error == .captureSessionRuntimeError:
            cameraSession.start()
        default:
            break
        }
    }
}
