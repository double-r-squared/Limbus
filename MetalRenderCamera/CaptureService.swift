/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A silent photo capture service with no UI or video support.
*/

//import AVFoundation
//
//actor CaptureService {
//    
//    // MARK: - Core Properties
//    private let captureSession = AVCaptureSession()
//    private let photoCapture = PhotoCapture()
//    private let deviceLookup = DeviceLookup()
//    
//    // MARK: - State Management
//    private var activeVideoInput: AVCaptureDeviceInput?
//    private var isConfigured = false
//    
//    // MARK: - Initialization
//    init() {
//        // Minimal setup for headless capture
//    }
//    
//    // MARK: - Authorization
//    var isAuthorized: Bool {
//        get async {
//            let status = AVCaptureDevice.authorizationStatus(for: .video)
//            var authorized = status == .authorized
//            
//            if status == .notDetermined {
//                authorized = await AVCaptureDevice.requestAccess(for: .video)
//            }
//            
//            return authorized
//        }
//    }
//    
//    // MARK: - Session Management
//    func start() async throws {
//        guard await isAuthorized, !captureSession.isRunning else { return }
//        
//        if !isConfigured {
//            try configureSession()
//            isConfigured = true
//        }
//        
//        captureSession.startRunning()
//    }
//    
//    private func configureSession() throws {
//        do {
//            let camera = try deviceLookup.defaultCamera
//            activeVideoInput = try addInput(for: camera)
//            try addOutput(photoCapture.output)
//            captureSession.sessionPreset = .photo
//        } catch {
//            throw CameraError.setupFailed
//        }
//    }
//    
//    // MARK: - Capture Operations
//    func capturePhoto(with features: PhotoFeatures) async throws -> Photo {
//        try await photoCapture.capturePhoto(with: features)
//    }
//    
//    // MARK: - Utility Methods
//    private func addInput(for device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
//        let input = try AVCaptureDeviceInput(device: device)
//        guard captureSession.canAddInput(input) else {
//            throw CameraError.addInputFailed
//        }
//        captureSession.addInput(input)
//        return input
//    }
//    
//    private func addOutput(_ output: AVCaptureOutput) throws {
//        guard captureSession.canAddOutput(output) else {
//            throw CameraError.addOutputFailed
//        }
//        captureSession.addOutput(output)
//    }
//}
