import SwiftUI

struct MailAITitleHeader: View {
    let title: String
    let subtitle: String
    var symbol: String = "apple.intelligence"
    var symbolSize: CGFloat = 18

    var body: some View {
        VStack(spacing: 8) {
            TimelineView(.animation) { timeline in
                let palette = sevenColorGradientPalette(for: timeline.date.timeIntervalSinceReferenceDate)
                let titleGradient = LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing)

                HStack(spacing: 8) {
                    Image(systemName: symbol)
                        .font(.system(size: symbolSize, weight: .semibold))
                        .foregroundStyle(titleGradient)

                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(titleGradient)
                }
                .shadow(color: .cyan.opacity(0.22), radius: 10, y: 3)
            }

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func sevenColorGradientPalette(for phase: TimeInterval) -> [Color] {
        let variants: [[Color]] = [
            [.red, .orange, .yellow, .green, .mint, .blue, .purple],
            [.pink, .red, .orange, .yellow, .teal, .blue, .indigo],
            [.cyan, .mint, .green, .yellow, .orange, .pink, .purple]
        ]
        let index = Int((phase / 2.0).rounded(.down)) % variants.count
        return variants[index]
    }
}

struct MailAILoadingView: View {
    let isActive: Bool
    let title: String
    let subtitle: String
    var symbol: String = "apple.intelligence"

    @State private var showOverlay = false
    @State private var revealAnimation = false

    var body: some View {
        Group {
            if showOverlay || isActive {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            LinearGradient(
                                colors: [Color.black.opacity(0.68), Color.blue.opacity(0.24), Color.purple.opacity(0.24)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .ignoresSafeArea()

                    VStack(spacing: 18) {
                        TimelineView(.animation) { timeline in
                            let phase = timeline.date.timeIntervalSinceReferenceDate
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.22), lineWidth: 2)
                                    .frame(width: 120, height: 120)
                                Circle()
                                    .trim(from: 0.12, to: 0.83)
                                    .stroke(
                                        AngularGradient(colors: [.cyan, .blue, .purple, .pink, .cyan], center: .center),
                                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                    )
                                    .frame(width: 120, height: 120)
                                    .rotationEffect(.degrees(phase * 150))
                                Image(systemName: symbol)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(height: 120)

                        Text(title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.82))
                    }
                    .padding(28)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.26), lineWidth: 1)
                    )
                    .scaleEffect(revealAnimation ? 1.08 : 1.0)
                    .blur(radius: revealAnimation ? 14 : 0)
                    .opacity(revealAnimation ? 0 : 1)
                }
                .transition(.opacity)
            }
        }
        .onAppear { updateOverlayState(isActive) }
        .onChange(of: isActive) { updateOverlayState($0) }
    }

    private func updateOverlayState(_ active: Bool) {
        if active {
            revealAnimation = false
            withAnimation(.easeInOut(duration: 0.2)) {
                showOverlay = true
            }
            return
        }

        guard showOverlay else { return }
        withAnimation(.easeInOut(duration: 0.42)) {
            revealAnimation = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            revealAnimation = false
            showOverlay = false
        }
    }
}
