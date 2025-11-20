//
//  ContentView.swift
//  AudioVisualizer
//
//  Created on 2025-11-19.
//

import SwiftUI

enum VisualizationMode: String, CaseIterable {
    case digital = "Digital"
    case analog = "Analog"
}

struct ContentView: View {
    @StateObject private var audioEngine = AudioEngine()
    @State private var sensitivity: Float = 1.0
    @State private var minDB: Float = -80
    @State private var maxDB: Float = -30
    @State private var trebleBoost: Float = 1.5
    @State private var showControls: Bool = false
    @State private var visualizationMode: VisualizationMode = .digital

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
                                maxHeight: geometry.size.height * (showControls ? 0.50 : 0.9),
                                mode: visualizationMode
                            )
                        }
                    }
                    .padding(.horizontal, 8)

                    Spacer()

                    // Collapsible Controls
                    if showControls {
                        VStack(spacing: 10) {
                            // Mode Picker
                            VStack(spacing: 4) {
                                Text("Visualization Mode")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.8))

                                Picker("Mode", selection: $visualizationMode) {
                                    ForEach(VisualizationMode.allCases, id: \.self) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .colorMultiply(.white)
                            }

                            // Sensitivity slider
                            VStack(spacing: 4) {
                                Text("Sensitivity: \(String(format: "%.1f", sensitivity))x")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.8))

                                HStack {
                                    Text("0.5")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.5))

                                    Slider(value: $sensitivity, in: 0.5...3.0, step: 0.1)
                                        .tint(.white.opacity(0.6))
                                        .onChange(of: sensitivity) { _, newValue in
                                            audioEngine.sensitivity = newValue
                                        }

                                    Text("3.0")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }

                            // Min dB slider
                            VStack(spacing: 4) {
                                Text("Min dB: \(Int(minDB))")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.8))

                                HStack {
                                    Text("-120")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.5))

                                    Slider(value: $minDB, in: -120...(-20), step: 5)
                                        .tint(.white.opacity(0.6))
                                        .onChange(of: minDB) { _, newValue in
                                            audioEngine.minDB = newValue
                                        }

                                    Text("-20")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }

                            // Max dB slider
                            VStack(spacing: 4) {
                                Text("Max dB: \(Int(maxDB))")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.8))

                                HStack {
                                    Text("-40")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.5))

                                    Slider(value: $maxDB, in: -40...0, step: 5)
                                        .tint(.white.opacity(0.6))
                                        .onChange(of: maxDB) { _, newValue in
                                            audioEngine.maxDB = newValue
                                        }

                                    Text("0")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }

                            // Treble Boost slider
                            VStack(spacing: 4) {
                                Text("Treble Boost: \(String(format: "%.1f", trebleBoost))x")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.8))

                                HStack {
                                    Text("0.0")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.5))

                                    Slider(value: $trebleBoost, in: 0.0...3.0, step: 0.1)
                                        .tint(.white.opacity(0.6))
                                        .onChange(of: trebleBoost) { _, newValue in
                                            audioEngine.trebleBoost = newValue
                                        }

                                    Text("3.0")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                // Info button (top-right)
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showControls.toggle()
                            }
                        }) {
                            Image(systemName: showControls ? "xmark.circle.fill" : "info.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(16)
                        }
                    }
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
        .statusBar(hidden: true)
        .onAppear {
            audioEngine.minDB = minDB
            audioEngine.maxDB = maxDB
            audioEngine.trebleBoost = trebleBoost
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
    let mode: VisualizationMode

    // Animation state
    @State private var animatedAmplitude: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()

                if mode == .digital {
                    // Digital mode: smooth continuous bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barGradient)
                        .frame(
                            width: geometry.size.width,
                            height: max(4, animatedAmplitude * maxHeight)
                        )
                } else {
                    // Analog mode: 10 discrete LED boxes
                    analogLEDBar(width: geometry.size.width)
                }
            }
        }
        .onChange(of: amplitude) { _, newValue in
            withAnimation(.linear(duration: 0.016)) {
                animatedAmplitude = CGFloat(newValue)
            }
        }
    }

    // Analog LED-style bar with 10 boxes
    private func analogLEDBar(width: CGFloat) -> some View {
        let boxCount = 10
        let spacing: CGFloat = 3
        let totalSpacing = spacing * CGFloat(boxCount - 1)
        let boxHeight = (maxHeight - totalSpacing) / CGFloat(boxCount)
        let litBoxCount = Int(animatedAmplitude * CGFloat(boxCount))

        return VStack(spacing: spacing) {
            // Draw boxes from top (index 9) to bottom (index 0)
            ForEach((0..<boxCount).reversed(), id: \.self) { index in
                let isLit = index < litBoxCount

                RoundedRectangle(cornerRadius: 3)
                    .fill(boxColor(for: index, isLit: isLit))
                    .frame(width: width, height: boxHeight)
                    .shadow(color: isLit ? boxColor(for: index, isLit: true).opacity(0.6) : .clear, radius: isLit ? 4 : 0)
            }
        }
        .frame(height: maxHeight)
    }

    // Color for each box based on position
    private func boxColor(for index: Int, isLit: Bool) -> Color {
        if !isLit {
            // Unlit: very dark gray
            return Color(white: 0.1)
        }

        // Boxes 0-4 (bottom 5): Green
        // Boxes 5-7 (middle 3): Yellow
        // Boxes 8-9 (top 2): Red
        switch index {
        case 0...4:
            return Color(red: 0, green: 1, blue: 0) // Green
        case 5...7:
            return Color(red: 1, green: 1, blue: 0) // Yellow
        default:
            return Color(red: 1, green: 0, blue: 0) // Red
        }
    }

    // Color gradient based on fill percentage (for digital mode)
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
