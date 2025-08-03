//
//  ImagePickerView.swift
//  Metal Camera
//
//  Created by Nate  on 7/23/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//

import SwiftUI
import CoreGraphics

// MARK: - Image Display Extension
extension PatientDetailView {
    
    /// Returns the appropriate image based on current selection
    var displayImage: UIImage? {
        switch imageSelection {
        case "Point":
            return processedImage // Image with points drawn
        case "Zernike":
            return heatmapImage
        case "3D":
            return generate3DVisualization() ?? processedImage
        case "Initial":
            return image // Original unprocessed image
        default:
            return processedImage
        }
    }
    
    private var eyeLabel: String {
        return eyeType.displayName
    }
    
    var ImageView: some View {
        Group {
            if let currentImage = displayImage {
                imageContentView(currentImage)
            } else {
                PulsatingGradientRing()
            }
        }
    }
    
    // Separate the image content into its own view to reduce complexity
    private func imageContentView(_ currentImage: UIImage) -> some View {
        Image(uiImage: currentImage)
            .resizable()
            .scaledToFill()
            .scaleEffect(totalScaleEffect)
            .offset(totalOffset)
            .gesture(combinedGesture)
            .frame(width: 400, height: 600)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(overlayContent)
            .transition(imageTransition)
            .animation(.easeInOut(duration: 0.8), value: imageSelection)
            .id(imageSelection) // Force view refresh when selection changes
            .onAppear {
                setupInitialZoom()
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
    }
    
    // Computed properties to break down complex expressions
    private var totalScaleEffect: CGFloat {
        (currentZoom + totalZoom) * initialZoom
    }
    
    private var totalOffset: CGSize {
        CGSize(
            width: offset.width + currentOffset.width,
            height: offset.height + currentOffset.height
        )
    }
    
    private var combinedGesture: some Gesture {
        SimultaneousGesture(
            magnificationGesture,
            dragGesture
        )
    }
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                currentZoom = value - 1
            }
            .onEnded { value in
                totalZoom += currentZoom
                totalZoom = min(max(totalZoom, 0.5), 4)
                currentZoom = 0
                if totalZoom <= 1 {
                    withAnimation(.easeOut(duration: 0.3)) {
                        offset = .zero
                    }
                }
            }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if totalZoom > 1 {
                    currentOffset = value.translation
                }
            }
            .onEnded { value in
                if totalZoom > 1 {
                    offset.width += value.translation.width
                    offset.height += value.translation.height
                    currentOffset = .zero
                    let maxOffset: CGFloat = 100 * totalZoom
                    offset.width = min(max(offset.width, -maxOffset), maxOffset)
                    offset.height = min(max(offset.height, -maxOffset), maxOffset)
                }
            }
    }
    
    private var imageTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.95)),
            removal: .opacity.combined(with: .scale(scale: 1.05))
        )
    }
    
    private var overlayContent: some View {
        ZStack {
            gradientOverlay
            contentOverlay
        }
    }
    
    private var gradientOverlay: some View {
        VStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(uiColor: .systemBackground),
                    Color(uiColor: .systemBackground).opacity(0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)
            .cornerRadius(6)
            
            Spacer()
            
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(uiColor: .systemBackground).opacity(0),
                    Color(uiColor: .systemBackground)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            .cornerRadius(6)
        }
        .allowsHitTesting(false)
    }
    
    private var contentOverlay: some View {
        VStack {
            topOverlayContent
            Spacer()
            bottomOverlayContent
        }
    }
    
    private var topOverlayContent: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(patient.firstName): \(eyeLabel)")
                    .font(.title.bold())
                    .foregroundColor(.primary)
                
                // Show current image mode
                Text("Mode: \(imageSelection)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(Capsule())
            }
            .padding(.leading, 8)
            
            Spacer()
            
            if isProcessing {
                ProgressView()
                    .scaleEffect(0.8)
                    .padding(.trailing, 8)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var bottomOverlayContent: some View {
        HStack {
            zoomStepper
            Spacer()
            settingsButton
        }
    }
    
    private var zoomStepper: some View {
        Stepper(
            value: Binding(
                get: { totalZoom },
                set: { newValue in
                    totalZoom = newValue
                    if newValue <= 1 {
                        withAnimation(.easeOut(duration: 0.3)) {
                            offset = .zero
                        }
                    }
                }
            ),
            in: 0.5...4,
            step: 0.5
        ) {
            Text("\(Int(totalZoom * 100))%")
                .font(.caption)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
        .opacity(0.9)
        .labelsHidden()
        .padding(.leading, 6)
        .padding(.vertical, 8)
    }
    
    private var settingsButton: some View {
        Button(action: {
            showPointEditor = true
        }) {
            Image(systemName: "slider.horizontal.3")
                .foregroundColor(.primary)
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
        .opacity(0.9)
        .padding(.trailing, 6)
        .padding(.vertical, 8)
        .sheet(isPresented: $showPointEditor) {
            PointEditorView(
                image: image,
                ringCenters: ringCenters,
                isPresented: $showPointEditor,
                numSamples: $numSamples,
                numAngles: $numAngles,
                threshold: $threshold,
                slopeCoef: $slopeCoef,
                referanceDistance: $referanceDistance,
                onReprocess: {
                    processImageAndZernikeMap()
                }
            )
        }
    }
    
    private func setupInitialZoom() {
        let imageSize = image.size
        let containerSize: CGFloat = 400
        let scaleToFitWidth = containerSize / imageSize.width
        initialZoom = scaleToFitWidth * 2
    }
}

// Text("Loading \(imageSelection)...")

