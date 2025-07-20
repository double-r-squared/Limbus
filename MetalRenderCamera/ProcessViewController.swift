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
    var onSave: ((Patient, UIImage, EyeType, Float) -> Void)?
    
    private let imageView = UIImageView()
    private let scoreLabel = UILabel()
    private let eyeSelectionView = UIView()
    private let eyeSegmentedControl = UISegmentedControl(items: EyeType.allCases.map { $0.displayName })
    private let eyeSelectionLabel = UILabel()
    private let buttonStack = UIStackView()
    
    private var selectedEye: EyeType? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupImageView()
        setupScoreLabel()
        setupEyeSelection()
        setupActionButtons()
        logDiagnosticInfo()
    }
    
    private func setupImageView() {
        imageView.contentMode = .scaleAspectFill // Changed to fill for proper clipping
        imageView.clipsToBounds = true // Enable clipping
        
        if let texture = capturedTexture {
            capturedImage = texture.toUIImage()
            imageView.image = capturedImage
            
            let imageSize = CGSize(
                width: view.bounds.width,
                height: view.bounds.height
            )
            
            // Calculate square size based on the smaller dimension
            let squareSize = min(imageSize.width, imageSize.height)
            
            // Set frame to square dimensions
            imageView.frame = CGRect(
                origin: CGPoint(
                    x: (view.bounds.width - squareSize) / 2,
                    y: view.safeAreaInsets.top + 40
                ),
                size: CGSize(width: squareSize, height: squareSize)
            )
            
            // Make it a perfect square with rounded corners (optional)
            imageView.layer.cornerRadius = 8
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
            y: imageView.frame.maxY - 40, // in the image at bottom
            width: view.bounds.width - 40,
            height: 30
        )
        view.addSubview(scoreLabel)
    }
    
    private func setupEyeSelection() {
        // Container view for eye selection
        eyeSelectionView.backgroundColor = .secondarySystemBackground
        eyeSelectionView.layer.cornerRadius = 12
        eyeSelectionView.frame = CGRect(
            x: 20,
            y: scoreLabel.frame.maxY + 30,
            width: view.bounds.width - 40,
            height: 80
        )
        view.addSubview(eyeSelectionView)
        
        // Label
        eyeSelectionLabel.text = "Select Eye:"
        eyeSelectionLabel.font = .systemFont(ofSize: 18, weight: .medium)
        eyeSelectionLabel.textColor = .label
        eyeSelectionLabel.frame = CGRect(
            x: 16,
            y: 12,
            width: eyeSelectionView.bounds.width - 32,
            height: 25
        )
        eyeSelectionView.addSubview(eyeSelectionLabel)
        
        // Segmented control
        eyeSegmentedControl.selectedSegmentIndex = -1 // No selection initially
        eyeSegmentedControl.backgroundColor = .systemBackground
        eyeSegmentedControl.selectedSegmentTintColor = .systemBlue
        eyeSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        eyeSegmentedControl.addTarget(self, action: #selector(eyeSelectionChanged), for: .valueChanged)
        eyeSegmentedControl.frame = CGRect(
            x: 16,
            y: 40,
            width: eyeSelectionView.bounds.width - 32,
            height: 28
        )
        eyeSelectionView.addSubview(eyeSegmentedControl)
    }
    
    private func setupActionButtons() {
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 10
        
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
            x: 20,
            y: eyeSelectionView.frame.maxY + 30,
            width: view.bounds.width - 40,
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
    
    @objc private func eyeSelectionChanged() {
        let selectedIndex = eyeSegmentedControl.selectedSegmentIndex
        if selectedIndex >= 0 && selectedIndex < EyeType.allCases.count {
            selectedEye = EyeType.allCases[selectedIndex]
            print("Selected eye: \(selectedEye?.displayName ?? "None")")
        }
    }
    
    @objc private func close() {
        dismiss(animated: true)
    }
    
    @objc private func save() {
        // Check if eye is selected
        guard let selectedEye = selectedEye else {
            showEyeSelectionAlert()
            return
        }
        
        guard let patient = patient,
              let image = capturedImage,
              let brightness = capturedBrightness else {
            print("Missing required data for save")
            return
        }
        
        // Dismiss this view controller first
        dismiss(animated: true) { [weak self] in
            // Call the callback with eye type and brightness
            self?.onSave?(patient, image, selectedEye, brightness)
        }
    }
    
    private func showEyeSelectionAlert() {
        let alert = UIAlertController(
            title: "Eye Selection Required",
            message: "Please specify which eye this image represents before saving the record.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            // Optionally highlight the eye selection area
            self?.highlightEyeSelection()
        })
        
        present(alert, animated: true)
    }
    
    private func highlightEyeSelection() {
        // Add a subtle animation to draw attention to the eye selection
        UIView.animate(withDuration: 0.3, animations: {
            self.eyeSelectionView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            self.eyeSelectionView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.eyeSelectionView.transform = .identity
                self.eyeSelectionView.backgroundColor = .secondarySystemBackground
            }
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
