import SwiftUI

struct SessionStatusView: View {
    enum State: Equatable {
        case active
        case expired
        case loading
        case error(message: String)
    }

    let state: State
    let onPrimaryAction: () -> Void

    var body: some View {
        ZStack {
            driftingBackground
            content
                .padding(.horizontal, 28)
        }
        .ignoresSafeArea()
    }

    private var driftingBackground: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let base = Path(CGRect(origin: .zero, size: size))
                context.fill(base, with: .color(Color(hex: "#0A0F1E")))

                let p1 = CGPoint(
                    x: size.width * (0.2 + 0.1 * sin(t / 12)),
                    y: size.height * (0.3 + 0.1 * cos(t / 14))
                )
                let p2 = CGPoint(
                    x: size.width * (0.75 + 0.08 * cos(t / 11)),
                    y: size.height * (0.7 + 0.1 * sin(t / 13))
                )

                context.addFilter(.blur(radius: 60))
                context.fill(Path(ellipseIn: CGRect(x: p1.x - 140, y: p1.y - 140, width: 280, height: 280)), with: .color(Color.blue.opacity(0.35)))
                context.fill(Path(ellipseIn: CGRect(x: p2.x - 180, y: p2.y - 180, width: 360, height: 360)), with: .color(Color.purple.opacity(0.25)))
            }
        }
    }

    private var content: some View {
        VStack(spacing: 18) {
            Image(systemName: presentation.icon)
                .font(.system(size: 72, weight: .semibold))
                .foregroundStyle(presentation.color)

            Text(presentation.title)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(presentation.subtitle)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    onPrimaryAction()
                }
            }) {
                Text(presentation.buttonTitle)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(presentation.color)
            .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.combined(with: .scale))
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: stateHash)
    }

    private var stateHash: String {
        switch state {
        case .active: return "active"
        case .expired: return "expired"
        case .loading: return "loading"
        case .error(let message): return "error-\(message)"
        }
    }

    private var presentation: (icon: String, color: Color, title: String, subtitle: String, buttonTitle: String) {
        switch state {
        case .active:
            return (
                icon: "checkmark.shield.fill",
                color: .green,
                title: "Session Active",
                subtitle: "Your developer session is active and ready for secure workspace actions.",
                buttonTitle: "Refresh Session"
            )
        case .expired:
            return (
                icon: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                color: .orange,
                title: "Session Expired",
                subtitle: "Your session has expired. Re-authenticate to continue using protected SDK capabilities.",
                buttonTitle: "Sign In Again"
            )
        case .loading:
            return (
                icon: "hourglass.circle.fill",
                color: .blue,
                title: "Checking Session",
                subtitle: "Please wait while we validate your current session state.",
                buttonTitle: "Retry"
            )
        case .error(let message):
            return (
                icon: "xmark.octagon.fill",
                color: .red,
                title: "Session Error",
                subtitle: message,
                buttonTitle: "Retry"
            )
        }
    }
}
