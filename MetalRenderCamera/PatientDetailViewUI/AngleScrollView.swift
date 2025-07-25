//
//  AngleScrollView.swift
//  Metal Camera
//
//  Created by Nate  on 7/23/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//

import Foundation
import SwiftUI

extension PatientDetailView {
    
    struct AngleScrollView: View {
        let ringCenters: [Int: [(radius: Double, x: Double, y: Double)]]
        
        var body: some View {
            ZStack{
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<12) { i in
                            let angle = i * 30
                            if let rings = ringCenters[angle], !rings.isEmpty {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Angle \(angle)°")
                                        .font(.caption)
                                        .bold()
                                    Text("\(rings.count) rings")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(10)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.trailing)
                }
                .padding(.trailing)
                
                HStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(uiColor: .systemBackground), Color(uiColor: .systemBackground).opacity(0)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 40)
                    .cornerRadius(6)
                    
                    Spacer()
                    
                    LinearGradient(
                        gradient: Gradient(colors: [Color(uiColor: .systemBackground).opacity(0), Color(uiColor: .systemBackground)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 40)
                    .cornerRadius(6)
                    .padding(.trailing)
                    
                }
                .allowsHitTesting(false)
            }
        }
    }
}
