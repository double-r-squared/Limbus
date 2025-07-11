/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
An object that retrieves the primary camera device.
*/

import AVFoundation

/// An object that manages the primary camera device
final class DeviceLookup {
    
    // The primary camera discovery session (back camera by default)
    private let primaryCameraSession: AVCaptureDevice.DiscoverySession
    
    init() {
        // Configure for the best available back camera
        primaryCameraSession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        )
        
        // Set the preferred camera if not already configured
        if AVCaptureDevice.systemPreferredCamera == nil {
            AVCaptureDevice.userPreferredCamera = primaryCameraSession.devices.first
        }
    }
    
    /// Returns the system-preferred camera
    var defaultCamera: AVCaptureDevice {
        get throws {
            guard let videoDevice = AVCaptureDevice.systemPreferredCamera ?? primaryCameraSession.devices.first else {
                throw CameraError.videoDeviceUnavailable
            }
            return videoDevice
        }
    }
    
    #if !targetEnvironment(simulator)
    /// Validates camera availability (only in production)
    func validateCameraAvailable() throws {
        guard primaryCameraSession.devices.first != nil else {
            throw CameraError.videoDeviceUnavailable
        }
    }
    #endif
}
