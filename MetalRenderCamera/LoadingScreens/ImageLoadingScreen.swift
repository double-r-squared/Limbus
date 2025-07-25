//
//  Loading Screen.swift
//  Metal Camera
//
//  Created by Nate  on 7/25/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//

import Foundation
import SwiftUI

extension PatientDetailView {
    struct PulsatingGradientRing: View {
        @State private var ringScale: CGFloat = 0.2
        @State private var opacity: Double = 1.0
        @State private var isGrowing = true
        
        var body: some View {
            ZStack {
                // Pulsating radial gradient ring
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.purple.opacity(0.6),
                                Color.black.opacity(0.2),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 20,
                            endRadius: 100 * ringScale
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(ringScale)
                    .opacity(opacity)
                    .onAppear {
                        animateRing()
                    }
                
                // Center text
                VStack(spacing: 8) {
                    Text("Building Zernike Graph...")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Computing polynomial heatmap")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.9)),
                removal: .opacity.combined(with: .scale(scale: 1.1))
            ))
            .frame(width: 400, height: 600)
        }
        
        private func animateRing() {
            withAnimation(.easeInOut(duration: 2.0)) {
                if isGrowing {
                    ringScale = 2.0
                    opacity = 0.5
                } else {
                    ringScale = 0.4
                    opacity = 1.0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isGrowing.toggle()
                animateRing()
            }
        }
    }
}
