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
    @State private var trebleBoost: Float = 3.0
    @State private var bassCut: Float = 6.0
    @State private var showControls: Bool = false
    @State private var visualizationMode: VisualizationMode = .digital
    @State private var mirrorMode: Bool = false
    @State private var useLogarithmicFreq: Bool = true

    // Info alert states
    @State private var showingVisModeInfo = false
    @State private var showingMirrorInfo = false
    @State private var showingLogFreqInfo = false
    @State private var showingSensitivityInfo = false
    @State private var showingMinDBInfo = false
    @State private var showingMaxDBInfo = false
    @State private var showingBassCutInfo = false
    @State private var showingTrebleBoostInfo = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background
                Color.black.ignoresSafeArea()

                // Frequency bars
                VStack {
                    if mirrorMode {
                        // Mirror mode: bars radiate OUTWARD from center
                        Spacer()

                        VStack(spacing: 0) {
                            // Top half - bars extend UPWARD from center (flipped: false puts bar at bottom growing up)
                            HStack(spacing: 16) {
                                ForEach(0..<16, id: \.self) { index in
                                    FrequencyBar(
                                        amplitude: audioEngine.frequencyBands[index],
                                        maxHeight: geometry.size.height * (showControls ? 0.22 : 0.42),
                                        mode: visualizationMode,
                                        flipped: false
                                    )
                                }
                            }
                            .padding(.horizontal, 8)

                            // Center baseline
                            Rectangle()
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 1)

                            // Bottom half - bars extend DOWNWARD from center
                            HStack(spacing: 16) {
                                ForEach(0..<16, id: \.self) { index in
                                    FrequencyBar(
                                        amplitude: audioEngine.frequencyBands[index],
                                        maxHeight: geometry.size.height * (showControls ? 0.22 : 0.42),
                                        mode: visualizationMode,
                                        flipped: true
                                    )
                                }
                            }
                            .padding(.horizontal, 8)
                        }

                        Spacer()
                    } else {
                        // Normal mode: bars from bottom
                        HStack(spacing: 16) {
                            ForEach(0..<16, id: \.self) { index in
                                FrequencyBar(
                                    amplitude: audioEngine.frequencyBands[index],
                                    maxHeight: geometry.size.height * (showControls ? 0.50 : 0.9),
                                    mode: visualizationMode,
                                    flipped: false
                                )
                            }
                        }
                        .padding(.horizontal, 8)
                    }

                    Spacer()

                    // Collapsible Controls
                    if showControls {
                        VStack(spacing: 10) {
                            // Mode Picker
                            VStack(spacing: 4) {
                                HStack {
                                    Text("Visualization Mode")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    Button(action: { showingVisModeInfo = true }) {
                                        Image(systemName: "info.circle")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }

                                Picker("Mode", selection: $visualizationMode) {
                                    ForEach(VisualizationMode.allCases, id: \.self) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .colorMultiply(.white)
                            }

                            // Mirror Mode Toggle
                            HStack {
                                Toggle(isOn: $mirrorMode) {
                                    Text("Mirror Mode")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .tint(.white.opacity(0.6))
                                Button(action: { showingMirrorInfo = true }) {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }

                            // Frequency Distribution Toggle
                            HStack {
                                Toggle(isOn: $useLogarithmicFreq) {
                                    Text("Logarithmic Freq")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .tint(.white.opacity(0.6))
                                .onChange(of: useLogarithmicFreq) { _, newValue in
                                    audioEngine.useLogarithmicDistribution = newValue
                                }
                                Button(action: { showingLogFreqInfo = true }) {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }

                            // Sensitivity slider
                            VStack(spacing: 4) {
                                HStack {
                                    Text("Sensitivity: \(String(format: "%.1f", sensitivity))x")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    Button(action: { showingSensitivityInfo = true }) {
                                        Image(systemName: "info.circle")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }

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
                                HStack {
                                    Text("Min dB: \(Int(minDB))")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    Button(action: { showingMinDBInfo = true }) {
                                        Image(systemName: "info.circle")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }

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
                                HStack {
                                    Text("Max dB: \(Int(maxDB))")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    Button(action: { showingMaxDBInfo = true }) {
                                        Image(systemName: "info.circle")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }

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

                            // Bass Cut slider
                            VStack(spacing: 4) {
                                HStack {
                                    Text("Bass Cut: \(String(format: "%.1f", bassCut)) dB")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    Button(action: { showingBassCutInfo = true }) {
                                        Image(systemName: "info.circle")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }

                                HStack {
                                    Text("0")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.5))

                                    Slider(value: $bassCut, in: 0.0...20.0, step: 1.0)
                                        .tint(.white.opacity(0.6))
                                        .onChange(of: bassCut) { _, newValue in
                                            audioEngine.bassAttenuation = newValue
                                        }

                                    Text("20")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }

                            // Treble Boost slider
                            VStack(spacing: 4) {
                                HStack {
                                    Text("Treble Boost: \(String(format: "%.1f", trebleBoost))x")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    Button(action: { showingTrebleBoostInfo = true }) {
                                        Image(systemName: "info.circle")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }

                                HStack {
                                    Text("0")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.5))

                                    Slider(value: $trebleBoost, in: 0.0...10.0, step: 0.5)
                                        .tint(.white.opacity(0.6))
                                        .onChange(of: trebleBoost) { _, newValue in
                                            audioEngine.trebleBoost = newValue
                                        }

                                    Text("10")
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
            audioEngine.bassAttenuation = bassCut
            audioEngine.useLogarithmicDistribution = useLogarithmicFreq
            audioEngine.requestPermissionAndStart()
        }
        .onDisappear {
            audioEngine.stop()
        }
        // Info alerts
        .alert("Visualization Mode", isPresented: $showingVisModeInfo) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("Digital: Smooth gradient bars\nAnalog: Discrete LED-style boxes (20 per bar)\n\nChoose your preferred aesthetic!")
        }
        .alert("Mirror Mode", isPresented: $showingMirrorInfo) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("Creates a symmetrical butterfly effect where bars radiate outward from the center of the screen in both directions.\n\nGreat for fullscreen music visualization!")
        }
        .alert("Logarithmic Frequency", isPresented: $showingLogFreqInfo) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("Logarithmic: Each bar covers ~1 octave (how we hear music)\nLinear: Each bar covers equal Hz (technical/scientific)\n\nKeep logarithmic ON for music visualization!")
        }
        .alert("Sensitivity", isPresented: $showingSensitivityInfo) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("Multiplies the final bar height after all processing.\n\nHigher = more movement\nLower = more stable\n\nAdjust after setting dB range.")
        }
        .alert("Min dB", isPresented: $showingMinDBInfo) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("The quietest sound level that registers as 0% bar height.\n\nLower values (-90 to -100) = more sensitive\nHigher values (-60 to -70) = less sensitive\n\nFor ambient mic capture: try -80 to -90")
        }
        .alert("Max dB", isPresented: $showingMaxDBInfo) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("The loudest sound level that registers as 100% bar height.\n\nLower values = bars hit max more easily\nHigher values = need louder sounds for full bars\n\nFor ambient mic capture: try -20 to -30")
        }
        .alert("Bass Cut", isPresented: $showingBassCutInfo) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("Reduces the left 3-4 bars (bass frequencies) to minimize constant activity from ambient room noise.\n\n0 dB = no reduction\n10 dB = moderate reduction\n20 dB = strong reduction\n\nUseful when bars are always lit from air sounds.")
        }
        .alert("Treble Boost", isPresented: $showingTrebleBoostInfo) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("Amplifies the right 8 bars (high frequencies) to make them more responsive. Music naturally has more bass energy.\n\n1-3 = subtle boost\n5-7 = strong boost\n8-10 = extreme boost\n\nIncrease if right bars are too quiet.")
        }
    }
}

struct FrequencyBar: View {
    let amplitude: Float
    let maxHeight: CGFloat
    let mode: VisualizationMode
    var flipped: Bool = false

    // Animation state
    @State private var animatedAmplitude: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            VStack {
                if flipped {
                    // Flipped: bars grow downward from top
                    if mode == .digital {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barGradientFlipped)
                            .frame(
                                width: geometry.size.width,
                                height: max(4, animatedAmplitude * maxHeight)
                            )
                    } else {
                        analogLEDBar(width: geometry.size.width, flipped: true)
                    }
                    Spacer()
                } else {
                    // Normal: bars grow upward from bottom
                    Spacer()
                    if mode == .digital {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barGradient)
                            .frame(
                                width: geometry.size.width,
                                height: max(4, animatedAmplitude * maxHeight)
                            )
                    } else {
                        analogLEDBar(width: geometry.size.width, flipped: false)
                    }
                }
            }
        }
        .onChange(of: amplitude) { _, newValue in
            withAnimation(.linear(duration: 0.016)) {
                animatedAmplitude = CGFloat(newValue)
            }
        }
    }

    // Analog LED-style bar with 20 boxes
    private func analogLEDBar(width: CGFloat, flipped: Bool = false) -> some View {
        let boxCount = 20
        let spacing: CGFloat = 3
        let totalSpacing = spacing * CGFloat(boxCount - 1)
        let boxHeight = (maxHeight - totalSpacing) / CGFloat(boxCount)
        let litBoxCount = Int(animatedAmplitude * CGFloat(boxCount))

        return VStack(spacing: spacing) {
            if flipped {
                // Flipped: draw boxes from bottom (index 0) to top (index 19)
                ForEach(0..<boxCount, id: \.self) { index in
                    let isLit = index < litBoxCount
                    let color = boxColor(for: index, isLit: isLit)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: width, height: boxHeight)
                        .shadow(color: isLit ? color.opacity(0.8) : .clear, radius: isLit ? 8 : 0, x: 0, y: 0)
                }
            } else {
                // Normal: draw boxes from top (index 19) to bottom (index 0)
                ForEach((0..<boxCount).reversed(), id: \.self) { index in
                    let isLit = index < litBoxCount
                    let color = boxColor(for: index, isLit: isLit)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: width, height: boxHeight)
                        .shadow(color: isLit ? color.opacity(0.8) : .clear, radius: isLit ? 8 : 0, x: 0, y: 0)
                }
            }
        }
        .frame(height: maxHeight)
    }

    // Color for each box based on position (20 boxes)
    private func boxColor(for index: Int, isLit: Bool) -> Color {
        if !isLit {
            // Unlit: very dark gray
            return Color(white: 0.1)
        }

        // Boxes 0-9 (bottom 10): Green
        // Boxes 10-14 (middle 5): Yellow
        // Boxes 15-19 (top 5): Red
        switch index {
        case 0...9:
            return Color(red: 0, green: 1, blue: 0) // Green
        case 10...14:
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

    // Flipped gradient for mirror mode (grows downward from center)
    // Green at top (center baseline), red at bottom (outer edge)
    private var barGradientFlipped: LinearGradient {
        let fillPercentage = Double(amplitude)

        // Calculate colors based on thresholds
        let bottomColor = barColor(for: 0)
        let middleColor = barColor(for: fillPercentage * 0.5)
        let topColor = barColor(for: fillPercentage)

        return LinearGradient(
            colors: [bottomColor, middleColor, topColor],
            startPoint: .top,
            endPoint: .bottom
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
