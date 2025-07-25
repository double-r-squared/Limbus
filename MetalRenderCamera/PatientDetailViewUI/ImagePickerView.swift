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
            return  heatmapImage
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
                Image(uiImage: currentImage)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect((currentZoom + totalZoom) * initialZoom)
                    .offset(x: offset.width + currentOffset.width, y: offset.height + currentOffset.height)
                    .gesture(
                        SimultaneousGesture(
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
                                },
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
                        )
                    )
                    .frame(width: 400, height: 600)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        ZStack {
                            VStack {
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(uiColor: .systemBackground), Color(uiColor: .systemBackground).opacity(0)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 80)
                                .cornerRadius(6)
                                
                                Spacer()
                                
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(uiColor: .systemBackground).opacity(0), Color(uiColor: .systemBackground)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 20)
                                .cornerRadius(6)
                            }
                            .allowsHitTesting(false)
                            
                            VStack {
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
                                
                                Spacer()
                                
                                HStack {
                                    Stepper(value: $totalZoom, in: 0.5...4, step: 0.5) {
                                        Text("\(Int(totalZoom * 100))%")
                                            .font(.caption)
                                    }
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(Capsule())
                                    .opacity(0.9)
                                    .labelsHidden()
                                    .onChange(of: totalZoom) { newValue in
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            if newValue <= 1 {
                                                offset = .zero
                                            }
                                        }
                                    }
                                    .padding(.leading, 6)
                                    .padding(.vertical, 8)
                                    
                                    Spacer()
                                    
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
                                            ringCenters: $ringCenters,
                                            isPresented: $showPointEditor
                                        )
                                    }
                                }
                            }
                        }
                    )
                    // Add smooth transition animation
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .scale(scale: 1.05))
                    ))
                    .animation(.easeInOut(duration: 0.8), value: imageSelection)
                    .id(imageSelection) // Force view refresh when selection changes
                    .onAppear {
                        let imageSize = image.size
                        let containerSize: CGFloat = 400
                        let scaleToFitWidth = containerSize / imageSize.width
                        initialZoom = scaleToFitWidth * 2
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                // Loading Overlay
            } else  {
                PulsatingGradientRing()
            }
        }
    }
}

// Text("Loading \(imageSelection)...")

