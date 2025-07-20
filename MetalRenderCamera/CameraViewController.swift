//
//  CameraViewController.swift
//  MetalShaderCamera
//
//  Created by Alex Staravoitau on 24/04/2016.
//  Copyright © 2016 Old Yellow Bricks. All rights reserved.
//

import UIKit
import Metal
import SwiftUI

internal final class CameraViewController: MTKViewController {
    var session: MetalCameraSession?
    var patient: Patient?
    var eyeType: EyeType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.onFrameCaptured = { [weak self] (texture, brightness) in
            let processVC = ProcessViewController()
            processVC.capturedTexture = texture
            processVC.capturedBrightness = brightness
            processVC.patient = self?.patient
            
            // Add a callback for when save is pressed
            processVC.onSave = { [weak self] patient, image, eyeType, brightness in
                var updatedPatient = patient

                if updatedPatient.eyeData == nil {
                    updatedPatient.eyeData = EyeData()
                }

                switch eyeType {
                case .left:
                    updatedPatient.eyeData?.leftEyeImage = image
                    updatedPatient.eyeData?.leftEyeScore = brightness
                    updatedPatient.eyeData?.leftEyeTimestamp = Date()
                    print("Saved left eye data for \(updatedPatient.firstName)")

                case .right:
                    updatedPatient.eyeData?.rightEyeImage = image
                    updatedPatient.eyeData?.rightEyeScore = brightness
                    updatedPatient.eyeData?.rightEyeTimestamp = Date()
                    print("Saved right eye data for \(updatedPatient.firstName)")
                }

                DispatchQueue.main.async {
                    self?.navigateToPatientDetail(patient: updatedPatient, image: image, eyeType: eyeType)
                }
            }

            
            self?.present(processVC, animated: true)
        }
        session = MetalCameraSession(frameOrientation: .portrait, delegate: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        session?.start()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        session?.stop()
    }
    
    private func navigateToPatientDetail(patient: Patient, image: UIImage, eyeType: EyeType) {
        session?.stop()
        
        let swiftUIView = PatientDetailView(patient: patient, image: image, eyeType: eyeType)
        let hostingVC = UIHostingController(rootView: swiftUIView)
        let nav = UINavigationController(rootViewController: hostingVC)
        
        // Replace the entire window's root view controller
        if let window = view.window {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = nav
            })
        }
    }
}

// MARK: - MetalCameraSessionDelegate
extension CameraViewController: MetalCameraSessionDelegate {
    func metalCameraSession(_ session: MetalCameraSession, didReceiveFrameAsTextures textures: [MTLTexture], withTimestamp timestamp: Double) {
        self.texture = textures[0]
        DispatchQueue.main.async {
            self.title = "Patient: \(self.patient?.firstName ?? "Unknown")"
        }
    }
    
    func metalCameraSession(_ cameraSession: MetalCameraSession, didUpdateState state: MetalCameraSessionState, error: MetalCameraSessionError?) {
        switch state {
        case .error where error == .captureSessionRuntimeError:
            // Ignoring capture session runtime errors
            cameraSession.start()
        default:
            break
        }
        DispatchQueue.main.async {
            print("Metal camera: \(state)")
        }
        NSLog("Session changed state to \(state) with error: \(error?.localizedDescription ?? "None").")
    }
}
