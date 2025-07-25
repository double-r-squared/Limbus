//
//  PointEditor.swift
//  Metal Camera
//
//  Created by Nate  on 7/22/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//
import Foundation
import SwiftUI

extension PatientDetailView {
    
    struct PointEditorView: View {
        let image: UIImage
        @Binding var ringCenters: [Int: [(radius: Double, x: Double, y: Double)]]
        @Binding var isPresented: Bool
        
        // MARK: - State Management
        @State private var editMode: EditMode = .none
        @State private var draggedPointKey: String? = nil
        @State private var isDraggingCenter: Bool = false
        @State private var undoStack: [[Int: [(radius: Double, x: Double, y: Double)]]] = []
        @State private var scale: CGFloat = 1.0
        @State private var offset: CGSize = .zero
        @State private var centerPoint: CGPoint = CGPoint(x: 200, y: 200)
        
        // MARK: - Edit Modes
        enum EditMode {
            case none
            case individual
            case brush
        }
        
        // MARK: - Constants
        private let pointRadius: CGFloat = 1
        private let centerRadius: CGFloat = 12
        
        // MARK: - Computed Properties
        private var imageSize: CGSize {
            CGSize(width: image.size.width, height: image.size.height)
        }
        
        private var displaySize: CGSize {
            let maxWidth: CGFloat = 500
            let maxHeight: CGFloat = 500
            let aspectRatio = image.size.width / image.size.height
            
            if aspectRatio > 1 {
                // Landscape
                return CGSize(width: maxWidth, height: maxWidth / aspectRatio)
            } else {
                // Portrait or square
                return CGSize(width: maxHeight * aspectRatio, height: maxHeight)
            }
        }
        
        // Convert all ring centers to CGPoints for display
        private var allPoints: [(key: String, point: CGPoint, ringIndex: Int)] {
            var points: [(key: String, point: CGPoint, ringIndex: Int)] = []
            
            for (ringIndex, centers) in ringCenters {
                for (pointIndex, center) in centers.enumerated() {
                    let key = "\(ringIndex)_\(pointIndex)"
                    // Scale coordinates from image space to display space
                    let scaledX = (center.x / image.size.width) * displaySize.width
                    let scaledY = (center.y / image.size.height) * displaySize.height
                    let point = CGPoint(x: scaledX, y: scaledY)
                    points.append((key: key, point: point, ringIndex: ringIndex))
                }
            }
            
            return points
        }
        
        var body: some View {
            NavigationView {
                VStack(spacing: 16) {
                    // Controls
                    controlPanel
                    
                    // Main editing area
                    ZStack {
                        // Background image
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: displaySize.width, height: displaySize.height)
                            .clipped()
                        
                        // Zoom and pan container
                        ZStack {
                            // Center cross
                            centerCross
                            
                            // Ring center points
                            ForEach(allPoints, id: \.key) { item in
                                pointView(
                                    at: item.point,
                                    key: item.key,
                                    ringIndex: item.ringIndex
                                )
                            }
                        }
                        .scaleEffect(scale)
                        .offset(offset)
                        .clipped()
                    }
                    .frame(width: displaySize.width, height: displaySize.height)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(12)
                    .shadow(radius: 4)
                    .gesture(
                        SimultaneousGesture(
                            // Zoom gesture
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = max(0.5, min(3.0, value))
                                },
                            
                            // Pan gesture
                            DragGesture()
                                .onChanged { value in
                                    if editMode == .none {
                                        offset = value.translation
                                    }
                                }
                        )
                    )
                    
                    // Helper functions panel
                    helperPanel
                    
                    // Stats
                    statsPanel
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Point Editor")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("Cancel") {
                        // Restore from undo stack if available
                        if !undoStack.isEmpty {
                            ringCenters = undoStack.first!
                        }
                        isPresented = false
                    },
                    trailing: Button("Done") {
                        save()
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                )
            }
            .onAppear {
                setupInitialCenter()
            }
        }
        
        // MARK: - Control Panel
        private var controlPanel: some View {
            VStack {
                HStack {
                    Button("Individual") {
                        editMode = editMode == .individual ? .none : .individual
                    }
                    .foregroundColor(editMode == .individual ? .white : .blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(editMode == .individual ? Color.blue : Color.clear)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                    
                    Button("Brush") {
                        editMode = editMode == .brush ? .none : .brush
                    }
                    .foregroundColor(editMode == .brush ? .white : .red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(editMode == .brush ? Color.red : Color.clear)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red, lineWidth: 1)
                    )
                    
                    Spacer()
                }
                
                Text("Mode: \(editMode == .none ? "Pan/Zoom" : editMode == .individual ? "Individual Delete" : "Brush Delete")")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        
        // MARK: - Center Cross
        private var centerCross: some View {
            ZStack {
                // Horizontal line
                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: 20, height: 2)
                
                // Vertical line
                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: 2, height: 20)
                
                // Center dot
                Circle()
                    .fill(Color.yellow)
                    .frame(width: centerRadius, height: centerRadius)
            }
            .position(centerPoint)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDraggingCenter = true
                        centerPoint = value.location
                    }
                    .onEnded { _ in
                        isDraggingCenter = false
                        reProcessData()
                    }
            )
        }
        
        // MARK: - Point View
        private func pointView(at point: CGPoint, key: String, ringIndex: Int) -> some View {
            Circle()
                .fill(draggedPointKey == key ? Color.red.opacity(0.8) : colorForRing(ringIndex))
                .frame(width: pointRadius * 2, height: pointRadius * 2)
                .position(point)
                .scaleEffect(draggedPointKey == key ? 1.5 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: draggedPointKey == key)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if editMode == .individual {
                                draggedPointKey = key
                            } else if editMode == .brush {
                                deletePoint(key: key)
                            }
                        }
                        .onEnded { _ in
                            if editMode == .individual && draggedPointKey == key {
                                // Long press delete
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    if draggedPointKey == key {
                                        deletePoint(key: key)
                                        draggedPointKey = nil
                                    }
                                }
                            }
                            draggedPointKey = nil
                        }
                )
        }
        
        // MARK: - Helper Panel
        private var helperPanel: some View {
            HStack {
                Button("Undo") {
                    undo()
                }
                .disabled(undoStack.isEmpty)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(undoStack.isEmpty ? Color.gray.opacity(0.2) : Color.blue.opacity(0.1))
                .cornerRadius(6)
                
                Spacer()
                
                Button("Auto Clean") {
                    autoClean()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
                
                Spacer()
                
                Button("Reset Center") {
                    resetCenter()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
        }
        
        // MARK: - Stats Panel
        private var statsPanel: some View {
            VStack(spacing: 8) {
                HStack {
                    let totalPoints = ringCenters.values.reduce(0) { $0 + $1.count }
                    Text("Total Points: \(totalPoints)")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("Rings: \(ringCenters.keys.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Text("Center: (\(Int(centerPoint.x)), \(Int(centerPoint.y)))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        
        // MARK: - Helper Functions
        
        private func setupInitialCenter() {
            centerPoint = CGPoint(x: displaySize.width / 2, y: displaySize.height / 2)
            saveToUndoStack()
        }
        
        private func colorForRing(_ ringIndex: Int) -> Color {
            let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .cyan]
            return colors[ringIndex % colors.count]
        }
        
        private func deletePoint(key: String) {
            let components = key.split(separator: "_")
            guard components.count == 2,
                  let ringIndex = Int(components[0]),
                  let pointIndex = Int(components[1]) else { return }
            
            saveToUndoStack()
            
            if var centers = ringCenters[ringIndex] {
                centers.remove(at: pointIndex)
                if centers.isEmpty {
                    ringCenters.removeValue(forKey: ringIndex)
                } else {
                    ringCenters[ringIndex] = centers
                }
            }
        }
        
        private func saveToUndoStack() {
            undoStack.append(ringCenters)
            if undoStack.count > 20 { // Limit undo stack
                undoStack.removeFirst()
            }
        }
        
        private func undo() {
            guard !undoStack.isEmpty else { return }
            ringCenters = undoStack.removeLast()
        }
        
        private func resetCenter() {
            centerPoint = CGPoint(x: displaySize.width / 2, y: displaySize.height / 2)
            reProcessData()
        }
        
        private func reProcessData() {
            // Convert display center back to image coordinates
            let imageCenterX = (centerPoint.x / displaySize.width) * image.size.width
            let imageCenterY = (centerPoint.y / displaySize.height) * image.size.height
            
            print("Re-processing data with new center: (\(imageCenterX), \(imageCenterY)) in image coordinates")
            // Here you would trigger your re-processing logic
        }
        
        private func autoClean() {
            saveToUndoStack()
            
            let minimumDistance: Double = 10.0 // Minimum distance in image coordinates
            var cleanedRingCenters: [Int: [(radius: Double, x: Double, y: Double)]] = [:]
            
            for (ringIndex, centers) in ringCenters {
                var cleanedCenters: [(radius: Double, x: Double, y: Double)] = []
                
                // Remove points that are too close together
                for center in centers {
                    var tooClose = false
                    for existingCenter in cleanedCenters {
                        let distance = sqrt(pow(center.x - existingCenter.x, 2) + pow(center.y - existingCenter.y, 2))
                        if distance < minimumDistance {
                            tooClose = true
                            break
                        }
                    }
                    if !tooClose {
                        cleanedCenters.append(center)
                    }
                }
                
                if !cleanedCenters.isEmpty {
                    cleanedRingCenters[ringIndex] = cleanedCenters
                }
            }
            
            ringCenters = cleanedRingCenters
        }
        
        private func save() {
            print("Saving ring centers:")
            for (ringIndex, centers) in ringCenters.sorted(by: { $0.key < $1.key }) {
                print("Ring \(ringIndex): \(centers.count) points")
            }
            
            let imageCenterX = (centerPoint.x / displaySize.width) * image.size.width
            let imageCenterY = (centerPoint.y / displaySize.height) * image.size.height
            print("Center in image coordinates: (\(imageCenterX), \(imageCenterY))")
        }
    }
}
