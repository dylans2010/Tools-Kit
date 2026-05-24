import SwiftUI

struct Diag_ScreenBurnInView: View {
    @State private var testColor: Color = .white
    @State private var isFullScreen = false
    @State private var brightness: Double = 1.0
    @State private var autoAdvance = false
    @State private var currentIndex = 0
    @State private var timer: Timer?
    @Environment(\.dismiss) private var dismiss

    private let testColors: [(Color, String)] = [
        (.white, "White"),
        (.black, "Black"),
        (.red, "Red"),
        (.green, "Green"),
        (.blue, "Blue"),
        (Color(.systemGray3), "Gray 50%"),
        (Color(.systemGray5), "Gray 25%"),
    ]

    private let testPatterns: [String] = [
        "checkerboard", "gradient_h", "gradient_v", "inverse"
    ]

    var body: some View {
        if isFullScreen {
            fullScreenView
        } else {
            Form {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "display")
                            .font(.system(size: 40))
                            .foregroundStyle(.blue)
                        Text("Burn-In Detection")
                            .font(.headline)
                        Text("Display solid colors at full brightness to reveal image retention or burn-in on OLED displays. Look for ghost images, uneven brightness, or color tinting.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section("Test Colors") {
                    ForEach(testColors.indices, id: \.self) { i in
                        Button {
                            testColor = testColors[i].0
                            currentIndex = i
                            isFullScreen = true
                        } label: {
                            HStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(testColors[i].0)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                    )
                                Text(testColors[i].1)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Settings") {
                    Toggle("Auto-Advance (3s each)", isOn: $autoAdvance)

                    VStack(alignment: .leading) {
                        Text("Brightness: \(Int(brightness * 100))%")
                            .font(.subheadline)
                        Slider(value: $brightness, in: 0...1)
                    }
                }

                Section {
                    Button {
                        currentIndex = 0
                        testColor = testColors[0].0
                        isFullScreen = true
                        if autoAdvance { startAutoAdvance() }
                    } label: {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("Start Full Test Sequence")
                        }
                    }
                } footer: {
                    Text("Tap anywhere on the full-screen view to cycle colors. Swipe down to exit.")
                }
            }
            .navigationTitle("Screen Burn-In")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var fullScreenView: some View {
        ZStack {
            testColor
                .opacity(brightness)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button {
                        stopAutoAdvance()
                        isFullScreen = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.5))
                            .padding()
                    }
                }
                Spacer()
                Text(testColors[currentIndex].1)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.bottom, 20)
            }
        }
        .onTapGesture {
            advanceColor()
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.height > 100 {
                        stopAutoAdvance()
                        isFullScreen = false
                    }
                }
        )
        .statusBarHidden(true)
    }

    private func advanceColor() {
        currentIndex = (currentIndex + 1) % testColors.count
        testColor = testColors[currentIndex].0
        if currentIndex == 0 && !autoAdvance {
            stopAutoAdvance()
            isFullScreen = false
        }
    }

    private func startAutoAdvance() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            advanceColor()
        }
    }

    private func stopAutoAdvance() {
        timer?.invalidate()
        timer = nil
    }
}
