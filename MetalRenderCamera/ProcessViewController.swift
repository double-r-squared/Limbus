//
//  ProcessViewController.swift
//  MetalRenderCamera
//
//  Created by Nate  on 7/17/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//
import UIKit
import SwiftUI

class ProcessViewController: UIViewController {
    var capturedTexture: MTLTexture?
    var capturedImage: UIImage?
    var capturedBrightness: Float?
    var patient: Patient?
    var onSave: ((Patient, UIImage) -> Void)?
    
    private let imageView = UIImageView()
    private let scoreLabel = UILabel()
    private let buttonStack = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupImageView()
        setupScoreLabel()
        setupActionButtons()
        logDiagnosticInfo()
    }
    
    private func setupImageView() {
        imageView.contentMode = .scaleAspectFit
        if let texture = capturedTexture {
            capturedImage = texture.toUIImage() // HERE
            imageView.image = capturedImage
            let imageSize = CGSize(
                width: view.bounds.width / 1.5,
                height: view.bounds.height / 2
            )
            imageView.frame = CGRect(
                origin: CGPoint(
                    x: (view.bounds.width - imageSize.width) / 2,
                    y: view.safeAreaInsets.top + 40
                ),
                size: imageSize
            )
        }
        view.addSubview(imageView)
    }
    
    private func setupScoreLabel() {
        scoreLabel.text = String(format: "Score: %.2f", capturedBrightness ?? 0)
        scoreLabel.textAlignment = .center
        scoreLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        scoreLabel.textColor = .label
        scoreLabel.frame = CGRect(
            x: 20,
            y: imageView.frame.maxY + 20,
            width: view.bounds.width - 40,
            height: 30
        )
        view.addSubview(scoreLabel)
    }
    
    private func setupActionButtons() {
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 20
        
        let discardButton = createActionButton(
            title: "Discard",
            color: .systemRed,
            action: #selector(close)
        )
        
        let saveButton = createActionButton(
            title: "Save Record",
            color: .systemBlue,
            action: #selector(save)
        )
        
        buttonStack.addArrangedSubview(discardButton)
        buttonStack.addArrangedSubview(saveButton)
        
        buttonStack.frame = CGRect(
            x: 40,
            y: scoreLabel.frame.maxY + 40,
            width: view.bounds.width - 80,
            height: 50
        )
        
        view.addSubview(buttonStack)
    }
    
    private func createActionButton(title: String, color: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = color
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    private func logDiagnosticInfo() {
        print("Received Score: \(capturedBrightness ?? 0)")
        print("Current Patient: \(patient?.firstName ?? "Unknown")")
    }
    
    @objc private func close() {
        dismiss(animated: true)
    }
    
    @objc private func save() {
        guard let patient = patient,
              let image = capturedImage else {
            print("Missing required data for save")
            return
        }
        
        // Dismiss this view controller first
        dismiss(animated: true) { [weak self] in
            // Call the callback to handle navigation
            self?.onSave?(patient, image)
        }
    }
}

// MARK: - MTLTexture Extension
extension MTLTexture {
    func toUIImage() -> UIImage? {
        let width = self.width
        let height = self.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        
        var data = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        self.getBytes(&data,
                     bytesPerRow: bytesPerRow,
                     from: MTLRegionMake2D(0, 0, width, height),
                     mipmapLevel: 0)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue |
                         CGImageAlphaInfo.premultipliedFirst.rawValue
        
        guard let context = CGContext(data: &data,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bytesPerRow: bytesPerRow,
                                    space: colorSpace,
                                    bitmapInfo: bitmapInfo),
              let cgImage = context.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}
