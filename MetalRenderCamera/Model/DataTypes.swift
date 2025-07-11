/*
See the LICENSE.txt file for this sample's licensing information.
Abstract:
Supporting data types for the photo capture app.
*/

import AVFoundation

// MARK: - Supporting types

/// An enumeration that describes the current status of the camera.
enum CameraStatus {
    /// The initial status upon creation.
    case unknown
    /// A status that indicates a person disallows access to the camera or microphone.
    case unauthorized
    /// A status that indicates the camera failed to start.
    case failed
    /// A status that indicates the camera is successfully running.
    case running
    /// A status that indicates higher-priority media processing is interrupting the camera.
    case interrupted
}

/// An enumeration that defines the photo capture states
enum CaptureActivity {
    case idle
    /// A status that indicates the capture service is performing photo capture
    case photoCapture(willCapture: Bool = false)
    
    var willCapture: Bool {
        if case .photoCapture(let willCapture) = self {
            return willCapture
        }
        return false
    }
}

/// A structure that represents a captured photo
struct Photo: Sendable {
    let data: Data
    let isProxy: Bool
}

struct PhotoFeatures {
    let qualityPrioritization: QualityPrioritization
}

/// A structure that represents the capture capabilities
struct CaptureCapabilities {
    let isHDRSupported: Bool
    
    init(isHDRSupported: Bool = false) {
        self.isHDRSupported = isHDRSupported
    }
    
    static let unknown = CaptureCapabilities()
}

enum QualityPrioritization: Int, Identifiable, CaseIterable, CustomStringConvertible, Codable {
    var id: Self { self }
    case speed = 1
    case balanced
    case quality
    
    var description: String {
        switch self {
        case .speed: return "Speed"
        case .balanced: return "Balanced"
        case .quality: return "Quality"
        }
    }
}

enum CameraError: Error {
    case videoDeviceUnavailable
    case addInputFailed
    case addOutputFailed
    case setupFailed
    case deviceChangeFailed
}

protocol OutputService {
    associatedtype Output: AVCaptureOutput
    var output: Output { get }
    var captureActivity: CaptureActivity { get }
    var capabilities: CaptureCapabilities { get }
    func updateConfiguration(for device: AVCaptureDevice)
    func setVideoRotationAngle(_ angle: CGFloat)
}

extension OutputService {
    func setVideoRotationAngle(_ angle: CGFloat) {
        output.connection(with: .video)?.videoRotationAngle = angle
    }
    
    func updateConfiguration(for device: AVCaptureDevice) {}
}
