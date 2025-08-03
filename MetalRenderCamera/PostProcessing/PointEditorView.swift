//
//  PointEditorView.swift
//  Metal Camera
//
//  Created by Nate  on 7/28/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//

import Foundation
import SwiftUI

extension PatientDetailView {
    
    struct PointEditorView: View {
        let image: UIImage
        let ringCenters: [Int: [(radius: Double, x: Double, y: Double)]]
        @Binding var isPresented: Bool
        @Binding var numSamples: Int
        @Binding var numAngles: Int
        @Binding var threshold: Double
        @Binding var slopeCoef: Double
        @Binding var referanceDistance: Double
        
        let onReprocess: () -> Void
        
        @State private var tempNumSamples: Double
        @State private var tempNumAngles: Double
        @State private var tempThreshold: Double
        @State private var tempSlopeCoef: Double
        @State private var tempeReferanceDistance: Double
        
        init(image: UIImage,
             ringCenters: [Int: [(radius: Double, x: Double, y: Double)]],
             isPresented: Binding<Bool>,
             numSamples: Binding<Int>,
             numAngles: Binding<Int>,
             threshold: Binding<Double>,
             slopeCoef: Binding<Double>,
             referanceDistance: Binding<Double>,
             onReprocess: @escaping () -> Void) {
            self.image = image
            self.ringCenters = ringCenters
            self._isPresented = isPresented
            self._numSamples = numSamples
            self._numAngles = numAngles
            self._threshold = threshold
            self._slopeCoef = slopeCoef
            self._referanceDistance = referanceDistance
            self.onReprocess = onReprocess
            
            // Initialize temp values
            self._tempNumSamples = State(initialValue: Double(numSamples.wrappedValue))
            self._tempNumAngles = State(initialValue: Double(numAngles.wrappedValue))
            self._tempThreshold = State(initialValue: Double(threshold.wrappedValue))
            self._tempSlopeCoef = State(initialValue: Double(slopeCoef.wrappedValue))
            self._tempeReferanceDistance = State(initialValue: Double(referanceDistance.wrappedValue))
        }
        
        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("Processing Parameters")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Number of Samples: \(Int(tempNumSamples))")
                                .font(.headline)
                            Text("Controls the radial sampling density")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(value: $tempNumSamples, in: 100...1000, step: 50)
                                .accentColor(.blue)
                        }
                        .padding(.vertical, 4)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Number of Angles: \(Int(tempNumAngles))")
                                .font(.headline)
                            Text("Controls the angular sampling resolution")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(value: $tempNumAngles, in: 72...720, step: 36)
                                .accentColor(.green)
                        }
                        .padding(.vertical, 4)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Threshold: \(String(format: "%.2f", tempThreshold))")
                                .font(.headline)
                            Text("Pixel intensity threshold for detection")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(value: $tempThreshold, in: 0.1...1.0, step: 0.05)
                                .accentColor(.orange)
                        }
                        .padding(.vertical, 4)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Slope Coefficient: \(String(format: "%.2f", tempSlopeCoef))")
                                .font(.headline)
                            Text("Adjusts sensitivity to slope changes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(value: $tempSlopeCoef, in: 0.1...3.0, step: 0.1)
                                .accentColor(.purple)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Distance Between Rings: \(Int(tempeReferanceDistance))")
                            .font(.headline)
                        Text("Controls the Referance Distance Between Rings for Comparison to perfect Sphere")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: $tempeReferanceDistance, in: 0...20, step: 1)
                            .accentColor(.blue)
                    }
                    .padding(.vertical, 4)
                    
                    Section(header: Text("Current Analysis")) {
                        HStack {
                            Text("Detected Rings:")
                            Spacer()
                            Text("\(ringCenters.values.flatMap { $0 }.count)")
                                .font(.body.monospacedDigit())
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("Angles with Data:")
                            Spacer()
                            Text("\(ringCenters.keys.count)")
                                .font(.body.monospacedDigit())
                                .foregroundColor(.green)
                        }
                    }
                    
                    Section {
                        Button(action: applyChanges) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Apply Changes & Reprocess")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(hasNoChanges)
                        
                        Button(action: resetToDefaults) {
                            HStack {
                                Image(systemName: "arrow.uturn.backward")
                                Text("Reset to Defaults")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .navigationTitle("Processing Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            applyChanges()
                            isPresented = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        
        private var hasNoChanges: Bool {
            Int(tempNumSamples) == numSamples &&
            Int(tempNumAngles) == numAngles &&
            abs(tempThreshold - threshold) < 0.001 &&
            abs(tempSlopeCoef - slopeCoef) < 0.001
        }
        
        private func applyChanges() {
            numSamples = Int(tempNumSamples)
            numAngles = Int(tempNumAngles)
            threshold = tempThreshold
            slopeCoef = tempSlopeCoef
            
            // Trigger reprocessing
            onReprocess()
        }
        
        private func resetToDefaults() {
            tempNumSamples = 500
            tempNumAngles = 360
            tempThreshold = 0.5
            tempSlopeCoef = 1.0
        }
    }
}
