/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
An object that manages photo capture output.
*/

import AVFoundation

enum PhotoCaptureError: Error {
    case noPhotoData
}

final class PhotoCapture: OutputService {
    
    // MARK: - Properties
    @Published private(set) var captureActivity: CaptureActivity = .idle
    let output = AVCapturePhotoOutput()
    private var photoOutput: AVCapturePhotoOutput { output }
    private(set) var capabilities: CaptureCapabilities = .unknown
    
    // MARK: - Photo Capture
    
    func capturePhoto(with features: PhotoFeatures) async throws -> Photo {
        try await withCheckedThrowingContinuation { continuation in
            let photoSettings = createPhotoSettings(with: features)
            let delegate = PhotoCaptureDelegate(continuation: continuation)
            monitorProgress(of: delegate)
            photoOutput.capturePhoto(with: photoSettings, delegate: delegate)
        }
    }
    
    private func createPhotoSettings(with features: PhotoFeatures) -> AVCapturePhotoSettings {
        // Configure for highest quality photo capture
        var photoSettings = AVCapturePhotoSettings()
        
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        }
        
        if let previewFormat = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewFormat]
        }
        
        photoSettings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        
        if let prioritization = AVCapturePhotoOutput.QualityPrioritization(
            rawValue: features.qualityPrioritization.rawValue
        ) {
            photoSettings.photoQualityPrioritization = prioritization
        }
        
        return photoSettings
    }
    
    private func monitorProgress(of delegate: PhotoCaptureDelegate) {
        Task {
            for await activity in delegate.activityStream {
                captureActivity = activity
            }
        }
    }
    
    // MARK: - Configuration
    
    func updateConfiguration(for device: AVCaptureDevice) {
        photoOutput.maxPhotoDimensions = device.activeFormat.supportedMaxPhotoDimensions.last ?? .zero
        photoOutput.maxPhotoQualityPrioritization = .quality
        updateCapabilities()
    }
    
    private func updateCapabilities() {
        capabilities = CaptureCapabilities()
    }
}

// MARK: - Photo Capture Delegate

private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let continuation: CheckedContinuation<Photo, Error>
    private var photoData: Data?
    
    let activityStream: AsyncStream<CaptureActivity>
    private let activityContinuation: AsyncStream<CaptureActivity>.Continuation
    
    init(continuation: CheckedContinuation<Photo, Error>) {
        self.continuation = continuation
        (activityStream, activityContinuation) = AsyncStream.makeStream(of: CaptureActivity.self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        activityContinuation.yield(.photoCapture(willCapture: true))
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        photoData = photo.fileDataRepresentation()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        defer { activityContinuation.finish() }
        
        if let error {
            continuation.resume(throwing: error)
            return
        }
        
        guard let photoData else {
            continuation.resume(throwing: PhotoCaptureError.noPhotoData)
            return
        }
        
        continuation.resume(returning: Photo(data: photoData, isProxy: false))
    }
}
