//
//  ContentView.swift
//  AudioVisualizer
//
//  Created on 2025-11-19.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioEngine = AudioEngine()
    @State private var sensitivity: Float = 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background
                Color.black.ignoresSafeArea()

                // Frequency bars
                VStack {
                    HStack(spacing: 4) {
                        ForEach(0..<16, id: \.self) { index in
                            FrequencyBar(
                                amplitude: audioEngine.frequencyBands[index],
                                maxHeight: geometry.size.height * 0.75
                            )
                        }
                    }
                    .padding(.horizontal, 8)

                    Spacer()

                    // Sensitivity slider
                    VStack(spacing: 8) {
                        Text("Sensitivity: \(String(format: "%.1f", sensitivity))x")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))

                        HStack {
                            Text("0.5")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))

                            Slider(value: $sensitivity, in: 0.5...3.0, step: 0.1)
                                .tint(.white.opacity(0.6))
                                .onChange(of: sensitivity) { _, newValue in
                                    audioEngine.sensitivity = newValue
                                }

                            Text("3.0")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                }
            }
        }
        .ignoresSafeArea()
        .statusBar(hidden: true)
        .onAppear {
            audioEngine.requestPermissionAndStart()
        }
        .onDisappear {
            audioEngine.stop()
        }
    }
}

struct FrequencyBar: View {
    let amplitude: Float
    let maxHeight: CGFloat

    // Animation state
    @State private var animatedAmplitude: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()

                // The bar
                RoundedRectangle(cornerRadius: 4)
                    .fill(barGradient)
                    .frame(
                        width: geometry.size.width,
                        height: max(4, animatedAmplitude * maxHeight)
                    )
            }
        }
        .onChange(of: amplitude) { _, newValue in
            withAnimation(.linear(duration: 0.016)) {
                animatedAmplitude = CGFloat(newValue)
            }
        }
    }

    // Color gradient based on fill percentage
    private var barGradient: LinearGradient {
        let fillPercentage = Double(amplitude)

        // Calculate colors based on thresholds
        let bottomColor = barColor(for: 0)
        let middleColor = barColor(for: fillPercentage * 0.5)
        let topColor = barColor(for: fillPercentage)

        return LinearGradient(
            colors: [bottomColor, middleColor, topColor],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    // Determine color based on position in the bar (0.0 to 1.0)
    private func barColor(for position: Double) -> Color {
        // 0-50%: Green (#00FF00)
        // 50-75%: Yellow (#FFFF00)
        // 75-100%: Red (#FF0000)

        if position <= 0.5 {
            // Green to Yellow transition
            let t = position / 0.5
            return interpolateColor(
                from: Color(red: 0, green: 1, blue: 0),      // Green
                to: Color(red: 1, green: 1, blue: 0),         // Yellow
                progress: t
            )
        } else if position <= 0.75 {
            // Yellow to Red transition
            let t = (position - 0.5) / 0.25
            return interpolateColor(
                from: Color(red: 1, green: 1, blue: 0),       // Yellow
                to: Color(red: 1, green: 0, blue: 0),         // Red
                progress: t
            )
        } else {
            // Red
            return Color(red: 1, green: 0, blue: 0)
        }
    }

    private func interpolateColor(from: Color, to: Color, progress: Double) -> Color {
        // Get RGB components
        let fromComponents = UIColor(from).cgColor.components ?? [0, 0, 0, 1]
        let toComponents = UIColor(to).cgColor.components ?? [0, 0, 0, 1]

        let r = fromComponents[0] + (toComponents[0] - fromComponents[0]) * progress
        let g = fromComponents[1] + (toComponents[1] - fromComponents[1]) * progress
        let b = fromComponents[2] + (toComponents[2] - fromComponents[2]) * progress

        return Color(red: r, green: g, blue: b)
    }
}

#Preview {
    ContentView()
}
