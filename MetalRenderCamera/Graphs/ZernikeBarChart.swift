//
//  ZernikeBarChart.swift
//  Metal Camera
//
//  Created by Nate  on 7/21/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//

import SwiftUI
import Charts

extension PatientDetailView {
    struct ZernikeCoefBarChartView: View {
        let coefficients: [Double]
        let modes: [(n: Int, m: Int)]
        
        // Helper function for Unicode subscripts
        private func subscriptString(_ number: Int) -> String {
            let unicodeBase = 0x2080 // Unicode for subscript 0
            return String(number.description.map { char in
                guard let digit = Int(String(char)), digit >= 0, digit <= 9 else { return char }
                return Character(UnicodeScalar(unicodeBase + digit)!) // Convert to Character
            })
        }
        
        var body: some View {
            // Prepare data: Get top 10 coefficients by absolute value
            let topData = coefficients.enumerated()
                .map { (index: $0.offset, value: abs($0.element), mode: modes[$0.offset]) }
                .sorted { $0.value > $1.value }
                .prefix(10)
            
            // Create chart
            Chart {
                ForEach(topData, id: \.index) { data in
                    BarMark(
                        x: .value("Mode", "Z\(subscriptString(data.mode.n))\(subscriptString(data.mode.m))"),
                        y: .value("Coefficient", data.value)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 300)
        }
    }
}
