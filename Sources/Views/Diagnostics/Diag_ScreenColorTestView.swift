import SwiftUI

struct Diag_ScreenColorTestView: View {
    @State private var currentColorIndex = 0
    @State private var isAutoPlaying = false
    @State private var timer: Timer?

    private let colors: [(Color, String)] = [
        (.red, "Red"), (.green, "Green"), (.blue, "Blue"),
        (.white, "White"), (.black, "Black"), (.yellow, "Yellow"),
        (.cyan, "Cyan"), (.magenta, "Magenta"), (.orange, "Orange"),
        (.gray, "Gray 50%")
    ]

    var body: some View {
        ZStack {
            colors[currentColorIndex].0
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: currentColorIndex)

            VStack {
                Spacer()
                VStack(spacing: 12) {
                    Text(colors[currentColorIndex].1)
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())

                    HStack(spacing: 20) {
                        Button {
                            currentColorIndex = (currentColorIndex - 1 + colors.count) % colors.count
                        } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title)
                        }

                        Button {
                            toggleAutoPlay()
                        } label: {
                            Image(systemName: isAutoPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title)
                        }

                        Button {
                            currentColorIndex = (currentColorIndex + 1) % colors.count
                        } label: {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title)
                        }
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())

                    Text("\(currentColorIndex + 1) / \(colors.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Screen Color Test")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopAutoPlay() }
    }

    private func toggleAutoPlay() {
        if isAutoPlaying {
            stopAutoPlay()
        } else {
            isAutoPlaying = true
            timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                currentColorIndex = (currentColorIndex + 1) % colors.count
            }
        }
    }

    private func stopAutoPlay() {
        isAutoPlaying = false
        timer?.invalidate()
        timer = nil
    }
}
