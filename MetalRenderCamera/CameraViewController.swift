//
//  ViewController.swift
//  MetalShaderCamera
//
//  Created by Alex Staravoitau on 24/04/2016.
//  Copyright © 2016 Old Yellow Bricks. All rights reserved.
//

import UIKit
import Metal

internal final class CameraViewController: MTKViewController {
    var session: MetalCameraSession?
    
    deinit {
        print("OS Reclaiming Memory From CameraViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
}

// MARK: - MetalCameraSessionDelegate
extension CameraViewController: MetalCameraSessionDelegate {
    func metalCameraSession(_ session: MetalCameraSession, didReceiveFrameAsTextures textures: [MTLTexture], withTimestamp timestamp: Double) {
        self.texture = textures[0]
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
            NSLog("Metal camera: \(state)")
        }
        NSLog("Session changed state to \(state) with error: \(error?.localizedDescription ?? "None").")
    }
    
    
    //Reads the Calibration score to user for extra feedback
    func calibrationScore(_ session: MetalCameraSession, didReceiveFrameAsTextures textures: [MTLTexture], withTimestamp timestamp: Double) {
        self.brightness = brightness
        print("Brightness: \(brightness)")
        
        DispatchQueue.main.async {
            self.title = "Metal camera: \(self.brightness)"
        }
    }
    
    func NavigationController(_ session: MetalCameraSession, didReceiveFrameAsTextures textures: [MTLTexture], withTimestamp timestamp: Double) {
        if self.brightness > 0.5 {
            
            //Capture
            print("Image Captured")
            
            //load into temp storage for Decision
            
            capturedPhotoPreview()
        }
    }
    
    func capturedPhotoPreview() {
        
        //load info from storage
        //modal like image picker
    }
    
    
    //Image Capturing stuff
    
    
    //Exit
    func navigateToProcessView(){
        
    }
    
}
