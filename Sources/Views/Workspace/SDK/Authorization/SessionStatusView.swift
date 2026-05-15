import SwiftUI

struct SessionStatusView: View {
    enum StatusState {
        case active
        case expired
        case loading
        case error(message: String)
    }

    @State private var state: StatusState = .loading
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Animated Mesh Background
            meshGradientBackground
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                contentSection
                    .transition(.opacity.combined(with: .scale))

                Spacer()

                primaryButton
                    .padding(.bottom, 50)
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Simulate initial loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    state = .active
                }
            }
        }
    }

    // MARK: - Components

    private var meshGradientBackground: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let angle = now * 0.2

                let center1 = CGPoint(
                    x: size.width * (0.5 + 0.2 * cos(angle)),
                    y: size.height * (0.5 + 0.2 * sin(angle))
                )
                let center2 = CGPoint(
                    x: size.width * (0.5 + 0.3 * cos(angle * 0.7 + 1)),
                    y: size.height * (0.5 + 0.3 * sin(angle * 0.8 + 2))
                )

                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 10/255, green: 15/255, blue: 30/255)))

                context.addFilter(.blur(radius: 80))

                context.fill(
                    Path(Circle(center: center1, radius: size.width * 0.6)),
                    with: .radialGradient(
                        Gradient(colors: [Color.blue.opacity(0.4), .clear]),
                        center: center1,
                        startRadius: 0,
                        endRadius: size.width * 0.6
                    )
                )

                context.fill(
                    Path(Circle(center: center2, radius: size.width * 0.5)),
                    with: .radialGradient(
                        Gradient(colors: [Color.purple.opacity(0.3), .clear]),
                        center: center2,
                        startRadius: 0,
                        endRadius: size.width * 0.5
                    )
                )
            }
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        VStack(spacing: 20) {
            Image(systemName: statusIcon)
                .font(.system(size: 80))
                .foregroundStyle(statusColor)
                .symbolEffect(.bounce, value: statusIcon)

            VStack(spacing: 8) {
                Text(statusTitle)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text(statusSubtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }

    private var primaryButton: some View {
        Button(action: handlePrimaryAction) {
            Text(buttonLabel)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                )
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Computed Properties

    private var statusIcon: String {
        switch state {
        case .active: return "checkmark.shield.fill"
        case .expired: return "lock.shield.fill"
        case .loading: return "ellipsis.shield.fill"
        case .error: return "exclamationmark.shield.fill"
        }
    }

    private var statusColor: Color {
        switch state {
        case .active: return .green
        case .expired: return .orange
        case .loading: return .blue
        case .error: return .red
        }
    }

    private var statusTitle: String {
        switch state {
        case .active: return "Session Active"
        case .expired: return "Session Expired"
        case .loading: return "Verifying..."
        case .error: return "Session Error"
        }
    }

    private var statusSubtitle: String {
        switch state {
        case .active: return "Your developer identity is validated and active for this workspace."
        case .expired: return "Your security token has expired. Please authenticate again to continue."
        case .loading: return "Establishing secure connection to Tools-Kit identity provider."
        case .error(let msg): return msg
        }
    }

    private var buttonLabel: String {
        switch state {
        case .active: return "Continue to Workspace"
        case .expired: return "Sign In Again"
        case .loading: return "Cancel"
        case .error: return "Retry"
        }
    }

    // MARK: - Actions

    private func handlePrimaryAction() {
        switch state {
        case .active:
            dismiss()
        case .expired, .error:
            withAnimation { state = .loading }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { state = .active }
            }
        case .loading:
            dismiss()
        }
    }
}

private extension Path {
    static func Circle(center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
        return path
    }
}
