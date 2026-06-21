import SwiftUI
import Observation
import UIKit

@Observable
final class VoicePersonalizationViewModel {
    var selectedVoice: String = "American"
    var selectedColorIndex: Int = 0
    var pace: Double = 0.5
    var expressivity: Double = 0.5
    
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()

    init() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        selectionFeedback.prepare()
    }

    func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light: lightImpact.impactOccurred()
        case .medium: mediumImpact.impactOccurred()
        case .heavy: heavyImpact.impactOccurred()
        @unknown default: lightImpact.impactOccurred()
        }
    }

    func triggerSelectionHaptic() {
        selectionFeedback.selectionChanged()
    }

    func selectColor(index: Int) {
        if selectedColorIndex != index {
            selectedColorIndex = index
            triggerHaptic(.medium)
        }
    }
    
    func selectVoice(_ voice: String) {
        if selectedVoice != voice {
            selectedVoice = voice
            triggerSelectionHaptic()
        }
    }
}

struct PersonalizedVoiceExperience: View {
    @State private var viewModel = VoicePersonalizationViewModel()
    @Environment(\.dismiss) private var dismiss

    let voices = ["American", "British", "Australian", "Indian", "Irish", "South African"]
    let swatchColors: [Color] = [
        .green,
        Color(red: 245/255, green: 166/255, blue: 35/255), // Amber
        Color(red: 232/255, green: 99/255, blue: 28/255),  // Burnt Orange
        Color(red: 208/255, green: 49/255, blue: 45/255),  // Red
        Color(red: 142/255, green: 45/255, blue: 226/255) // Purple
    ]

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        siriOrb
                            .padding(.top, 60)
                            .frame(maxWidth: .infinity)
                        
                        voiceRow
                            .padding(.top, 24)

                        colorSwatchRow
                            .padding(.top, 24)

                        paceSlider
                            .padding(.top, 20)

                        expressivitySlider
                            .padding(.top, 24)

                        titleSubtitle
                            .padding(.top, 28)
                            .padding(.bottom, 100) // Space for continue button
                    }
                    .padding(.horizontal, 24)
                }
            }

            continueButton
        }
        .navigationBarHidden(true)
    }

    // MARK: - Components

    private var topBar: some View {
        HStack {
            Button {
                viewModel.triggerHaptic(.light)
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }
    
    private var siriOrb: some View {
        SiriOrbView()
            .frame(width: 340, height: 340)
    }
    
    private var voiceRow: some View {
        HStack {
            Text("Voice")
                .foregroundColor(.white)
                .font(.system(size: 17))
            
            Spacer()
            
            Menu {
                ForEach(voices, id: \.self) { voice in
                    Button {
                        viewModel.selectVoice(voice)
                    } label: {
                        HStack {
                            Text(voice)
                            if viewModel.selectedVoice == voice {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(viewModel.selectedVoice)
                        .font(.system(size: 15))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.15)))
            }
            .simultaneousGesture(TapGesture().onEnded {
                viewModel.triggerHaptic(.light)
            })
        }
    }
    
    private var colorSwatchRow: some View {
        HStack(spacing: 16) {
            ForEach(0..<swatchColors.count, id: \.self) { index in
                let isSelected = viewModel.selectedColorIndex == index
                Circle()
                    .fill(swatchColors[index])
                    .frame(width: 32, height: 32)
                    .overlay(
                        ZStack {
                            if isSelected {
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 40, height: 40)

                                Text("\(index + 1)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    )
                    .contentShape(Circle())
                    .onTapGesture {
                        viewModel.selectColor(index: index)
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var paceSlider: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pace")
                .foregroundColor(.white)
                .font(.system(size: 17))

            CustomSlider(value: $viewModel.pace, accentColor: .green, onIncrement: {
                viewModel.triggerSelectionHaptic()
            }, onReleased: {
                viewModel.triggerHaptic(.light)
            })
        }
    }
    
    private var expressivitySlider: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expressivity")
                .foregroundColor(.white)
                .font(.system(size: 17))

            CustomSlider(value: $viewModel.expressivity, accentColor: .green, onIncrement: {
                viewModel.triggerSelectionHaptic()
            }, onReleased: {
                viewModel.triggerHaptic(.light)
            })
        }
    }
    
    private var titleSubtitle: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Customize Your Siri Voice")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            Text("You'll hear this voice in Siri, Maps, and Safari.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var continueButton: some View {
        VStack {
            Spacer()
            Button {
                viewModel.triggerHaptic(.heavy)
                dismiss()
            } label: {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(red: 10/255, green: 132/255, blue: 255/255))
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24 + (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.bottom ?? 0)
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

struct SiriOrbView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Outer soft glow
            RadialGradient(
                gradient: Gradient(colors: [.white.opacity(0.3), .black]),
                center: .center,
                startRadius: 0,
                endRadius: 170
            )
            .frame(width: 340, height: 340)
            .blur(radius: 40)

            // Mid petal/hexagonal iridescent ring
            ZStack {
                ForEach(0..<6) { i in
                    Circle()
                        .fill(
                            AngularGradient(
                                gradient: Gradient(colors: [.pink, .cyan, .yellow, .purple, .pink]),
                                center: .center
                            )
                        )
                        .frame(width: 180, height: 180)
                        .opacity(0.15)
                        .offset(x: 40)
                        .rotationEffect(.degrees(Double(i) * 60))
                }
            }
            .blur(radius: 15)

            // Inner core
            Circle()
                .fill(.white)
                .frame(width: 95, height: 95)
                .shadow(color: .white, radius: 30)

            // Optional sparkle texture overlay
            Canvas { context, size in
                for _ in 0..<100 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let rect = CGRect(x: x, y: y, width: 1.5, height: 1.5)
                    let path = Path(ellipseIn: rect)
                    context.fill(path, with: .color(.white.opacity(0.3)))
                }
            }
            .frame(width: 280, height: 280)
            .mask(Circle())
        }
        .scaleEffect(isAnimating ? 1.05 : 0.95)
        .opacity(isAnimating ? 1.0 : 0.8)
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

struct CustomSlider: View {
    @Binding var value: Double
    var accentColor: Color
    var onIncrement: () -> Void
    var onReleased: () -> Void

    @State private var lastReportedValue: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 4)

                // Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor)
                    .frame(width: geometry.size.width * CGFloat(value), height: 4)

                // Thumb
                Circle()
                    .fill(.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .offset(x: geometry.size.width * CGFloat(value) - 12)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let newValue = min(max(0, Double(gesture.location.x / geometry.size.width)), 1.0)
                                value = newValue

                                // Haptic every 5%
                                if abs(value - lastReportedValue) >= 0.05 {
                                    onIncrement()
                                    lastReportedValue = value
                                }
                            }
                            .onEnded { _ in
                                onReleased()
                            }
                    )
            }
        }
        .frame(height: 24)
    }
}

#Preview {
    PersonalizedVoiceExperience()
}
