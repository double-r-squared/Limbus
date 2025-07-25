//
//  DataQualityStats.swift
//  Metal Camera
//
//  Created by Nate  on 7/23/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//

import Foundation
import SwiftUI

extension PatientDetailView {
    
    struct DataQualityView: View {
        let ringCenters: [Int: [(radius: Double, x: Double, y: Double)]]
        
        private var totalPoints: Int {
            ringCenters.values.flatMap { $0 }.count
        }
        
        private var angleCount: Int {
            ringCenters.keys.count
        }
        
        private var avgRings: Int {
            angleCount > 0 ? totalPoints / angleCount : 0
        }
        
        private var qualityScore: Double {
            // Threshold check: must detect at least 20 rings on average
            guard avgRings >= 20 else { return 0 }

            let pointsScore = min(Double(totalPoints) / 1000.0, 1.0)
            let angleScore = min(Double(angleCount) / 360.0, 1.0)
            
            let normalizedRings: Double
            if avgRings <= 32 {
                normalizedRings = Double(avgRings) / 32.0
            } else {
                // Gradually reduce score for over-detection
                normalizedRings = max(0.0, 1.0 - (Double(avgRings - 32) / 80.0))
            }

            let weightedScore = (pointsScore * 0.4 + angleScore * 0.3 + normalizedRings * 0.3)
            return weightedScore * 100
        }
        
        private var scoreColor: Color {
            switch qualityScore {
            case 80...: return .green
            case 50..<80: return .orange
            default: return .red
            }
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text("Data Quality:")
                    .font(.caption2)
                    .bold()
                
                Text("Points: \(totalPoints)")
                    .font(.caption2)
                    .opacity(0.5)
                
                Text("Angles Detected: \(angleCount)")
                    .font(.caption2)
                    .opacity(0.5)
                
                if angleCount > 0 {
                    Text("Rings Detected: \(avgRings)")
                        .font(.caption2)
                        .opacity(0.5)
                } else {
                    Text("Rings Detected: N/A")
                        .font(.caption2)
                        .opacity(0.5)
                }
                
                Text("Data Quality Score: \(String(format: "%.0f", qualityScore))%")
                    .font(.caption2)
                    .bold()
                    .foregroundColor(scoreColor)
            }
            .padding(.leading, 4)
            .padding(.bottom, 8)
        }
    }

}
