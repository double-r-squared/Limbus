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
import SwiftData

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
        
        if let window = view.window {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = nav
            })
        }
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
        self.texture = textures[0]
        DispatchQueue.main.async {
            self.title = "Patient: \(self.patient?.firstName ?? "Unknown")"
        }
    }
    
    func metalCameraSession(_ cameraSession: MetalCameraSession, didUpdateState state: MetalCameraSessionState, error: MetalCameraSessionError?) {
        switch state {
        case .error where error == .captureSessionRuntimeError:
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
