/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A headless camera controller for silent photo capture.
*/

import AVFoundation

final class CaptureCameraController {
    private(set) var status = CameraStatus.unknown
    private(set) var error: Error?
    
    private let captureService = CaptureService()
    private var qualityPrioritization = QualityPrioritization.quality
    
    init() {
        // Minimal setup - no UI components
    }
    
    // MARK: - Camera Control
    
    func start() async throws {
        guard await captureService.isAuthorized else {
            status = .unauthorized
            throw CameraError.unauthorized
        }
        
        do {
            try await captureService.start(with: CameraState())
            status = .running
        } catch {
            status = .failed
            throw error
        }
    }
    
    // MARK: - Photo Capture
    
    func capturePhoto() async throws -> Data {
        let photoFeatures = PhotoFeatures(qualityPrioritization: qualityPrioritization)
        let photo = try await captureService.capturePhoto(with: photoFeatures)
        return photo.data
    }
    
    // MARK: - Configuration
    
    func setQuality(_ quality: QualityPrioritization) {
        qualityPrioritization = quality
    }
}
