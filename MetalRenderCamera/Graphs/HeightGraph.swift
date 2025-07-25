//
//  PatientDetailExtension.swift
//  Metal Camera
//
//  Created by Nate  on 7/19/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//
import SwiftUI
import Charts

extension PatientDetailView {
    
    struct HeightGraph: View {
        let radiusHeightAtAngle: RadiusHeightAtAngleData
        @Binding var targetAngle: Int
        @Binding var rawSelectedIndex: Int?
        
        let linearGradient = LinearGradient(
            gradient: Gradient(colors: [Color.accentColor.opacity(0.4), Color.accentColor.opacity(0)]),
            startPoint: .top,
            endPoint: .bottom
        )
    
        var selectedIndex: Int? {
            rawSelectedIndex
        }
        
        // Chart point structure
        private struct DataPoint: Identifiable {
            let id: Int
            let radius: Double
            let height: Double
        }
        
        // Merge reversed opposite + current angle into a single array
        private var heightData: [DataPoint] {
            let oppositeAngle = (targetAngle + 180) % 360

            guard let current = radiusHeightAtAngle[targetAngle],
                  let opposite = radiusHeightAtAngle[oppositeAngle] else {
                return []
            }

            let mirroredOpposite = opposite.reversed().map {
                (radius: -$0.radius, height: $0.height)
            }

            let combined = mirroredOpposite + current

            return combined.enumerated().map {
                DataPoint(id: $0.offset, radius: $0.element.radius, height: $0.element.height)
            }
        }

        // Popover
        private func valueSelectionPopover(for point: DataPoint) -> some View {
            Text("r: \(point.radius, specifier: "%.2f")\nh: \(point.height, specifier: "%.2f")")
                .font(.caption2)
                .foregroundColor(.white)
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.8))
                        .shadow(radius: 2)
                )
        }
        
        var body: some View {
            VStack {
                if heightData.isEmpty {
                    Text("No data for angle \(targetAngle)° and \((targetAngle + 180) % 360)°")
                        .foregroundColor(.gray)
                        .frame(height: 200)
                } else {
                    Chart(heightData) { point in
                        LineMark(
                            x: .value("Radius", point.radius),
                            y: .value("Height", point.height)
                        )
                        .interpolationMethod(.cardinal)
                        .foregroundStyle(.blue)
                        
                        AreaMark(
                            x: .value("Radius", point.radius),
                            y: .value("Height", point.height)
                        )
                        .interpolationMethod(.cardinal)
                        .foregroundStyle(linearGradient)
                        
                        if let selectedIndex,
                           selectedIndex >= 0,
                           selectedIndex < heightData.count,
                           heightData[selectedIndex].id == point.id {
                            // RuleMark for vertical line
                            RuleMark(x: .value("Selected Radius", point.radius))
                                .foregroundStyle(Color.gray.opacity(0.3))
                                .offset(yStart: -10)
                                .zIndex(-1)
                            
                            // PointMark for circle at intersection
                            PointMark(
                                x: .value("Selected Radius", point.radius),
                                y: .value("Height", point.height),
                            )
                            .foregroundStyle(.blue)
                            .symbolSize(50) // Adjust size for visibility
                            .annotation(
                                position: .top,
                                spacing: 4, // Small spacing to hover just above the circle
                                overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                            ) {
                                valueSelectionPopover(for: point)
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.1))
                    .chartXSelection(value: $rawSelectedIndex)
                    .chartXAxisLabel("Radius")
                    .chartYAxisLabel("Height")
                    .frame(height: 200)
                }
            }
        }
    }
}
