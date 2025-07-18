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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.onFrameCaptured = { [weak self] (texture, brightness) in
            let processVC = ProcessViewController()
            processVC.capturedTexture = texture
            processVC.capturedBrightness = brightness
            processVC.patient = self?.patient
            
            // Add a callback for when save is pressed
            processVC.onSave = { [weak self] (patient, image) in
                self?.navigateToPatientDetail(patient: patient, image: image)
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
    
    private func navigateToPatientDetail(patient: Patient, image: UIImage) {
        session?.stop()
        
        let swiftUIView = PatientDetailView(patient: patient, image: image)
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
            self.title = "Score: \(self.brightness)% , Patient: \(self.patient?.firstName ?? "Unknown")"
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
