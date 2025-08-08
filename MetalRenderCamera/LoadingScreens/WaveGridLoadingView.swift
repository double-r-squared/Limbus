import SwiftUI

struct WaveGridLoadingView: View {
    @State private var waveOffset: CGFloat = 0
    @State private var time: Double = 0
    
    // Grid configuration
    private let dotSize: CGFloat = 8
    private let spacing: CGFloat = 25
    private let maxScale: CGFloat = 2.5
    private let waveSpeed: Double = 2.0
    private let waveLength: CGFloat = 200
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.05, blue: 0.2),
                        Color(red: 0.05, green: 0.1, blue: 0.25)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Grid of animated dots
                LazyVGrid(columns: createColumns(for: geometry.size.width), spacing: spacing) {
                    ForEach(0..<totalDots(for: geometry.size), id: \.self) { index in
                        let position = getDotPosition(index: index, screenSize: geometry.size)
                        let scale = calculateScale(for: position)
                        let opacity = calculateOpacity(for: scale)
                        
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(opacity),
                                        Color.cyan.opacity(opacity * 0.8),
                                        Color.blue.opacity(opacity * 0.6)
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: dotSize * scale / 2
                                )
                            )
                            .frame(width: dotSize, height: dotSize)
                            .scaleEffect(scale)
                            .animation(.easeInOut(duration: 0.3), value: scale)
                    }
                }
                .padding(20)
                
                // Loading text overlay
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Text("Loading")
                            .font(.system(size: 28, weight: .ultraLight, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white, Color.cyan.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        // Wave progress indicator
                        HStack(spacing: 4) {
                            ForEach(0..<5) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.7))
                                    .frame(width: 30, height: 4)
                                    .scaleEffect(x: getProgressScale(index: index), y: 1)
                                    .animation(
                                        .easeInOut(duration: 0.5)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.1),
                                        value: time
                                    )
                            }
                        }
                    }
                    .padding(.bottom, 80)
                }
            }
        }
        .onAppear {
            startWaveAnimation()
        }
    }
    
    private func createColumns(for screenWidth: CGFloat) -> [GridItem] {
        let columnCount = Int((screenWidth - 40) / spacing)
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }
    
    private func totalDots(for screenSize: CGSize) -> Int {
        let columns = Int((screenSize.width - 40) / spacing)
        let rows = Int((screenSize.height - 40) / spacing)
        return columns * rows
    }
    
    private func getDotPosition(index: Int, screenSize: CGSize) -> CGPoint {
        let columns = Int((screenSize.width - 40) / spacing)
        let row = index / columns
        let col = index % columns
        
        let x = CGFloat(col) * spacing + 20
        let y = CGFloat(row) * spacing + 20
        
        return CGPoint(x: x, y: y)
    }
    
    private func calculateScale(for position: CGPoint) -> CGFloat {
        // Create wave effect based on position and time
        let distance = sqrt(pow(position.x - waveOffset, 2) + pow(position.y - waveOffset * 0.6, 2))
        let wave = sin((distance - time * 100) / waveLength * 2 * .pi)
        
        // Create multiple overlapping waves
        let wave2 = sin((position.x - time * 80) / (waveLength * 1.5) * 2 * .pi) * 0.7
        let wave3 = sin((position.y - time * 60) / (waveLength * 2) * 2 * .pi) * 0.5
        
        let combinedWave = (wave + wave2 + wave3) / 3
        let normalizedWave = (combinedWave + 1) / 2 // Normalize to 0-1
        
        return 1 + (maxScale - 1) * normalizedWave
    }
    
    private func calculateOpacity(for scale: CGFloat) -> Double {
        // Higher scale = higher opacity for more dramatic effect
        let normalizedScale = (scale - 1) / (maxScale - 1)
        return 0.4 + normalizedScale * 0.6
    }
    
    private func getProgressScale(index: Int) -> CGFloat {
        let phase = (time * 2 + Double(index) * 0.3).truncatingRemainder(dividingBy: 2 * .pi)
        return 1 + 0.5 * CGFloat(sin(phase))
    }
    
    private func startWaveAnimation() {
        let timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            time += 1/60 * waveSpeed
            waveOffset = sin(time) * 100
        }
        RunLoop.current.add(timer, forMode: .common)
    }
}

// Preview
struct WaveGridLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        WaveGridLoadingView()
    }
}

// Usage example
struct ContentView: View {
    @State private var isLoading = true
    
    var body: some View {
        if isLoading {
            WaveGridLoadingView()
                .onAppear {
                    // Simulate loading time
                    DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                        isLoading = false
                    }
                }
        } else {
            // Your main app content
            VStack {
                Text("Welcome!")
                    .font(.largeTitle)
                    .fontWeight(.light)
                Text("Loading Complete")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}