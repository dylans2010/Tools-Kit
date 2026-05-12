import SwiftUI
import Combine

/// Manages a UIWindow that sits behind the system keyboard, rendering animated
/// gradient-glow effects so the keyboard appears to float on top of a living backdrop.
/// Modelled after KeyboardCustomizeManager (Portal) but scoped to AIGenerateSlides.
final class KeyboardBackdropManager: ObservableObject {
    nonisolated(unsafe) static let shared = KeyboardBackdropManager()

    @Published var isKeyboardVisible: Bool = false
    @Published var keyboardHeight: CGFloat = 0

    private var cancellables = Set<AnyCancellable>()
    private var backdropWindow: UIWindow?

    private init() {
        setupObservers()
    }

    // MARK: - Keyboard Observers

    private func setupObservers() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                self?.handleKeyboard(notification: notification, visible: true)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                self?.handleKeyboard(notification: notification, visible: false)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                self?.handleKeyboard(notification: notification, visible: true)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.hideWindow(duration: 0)
            }
            .store(in: &cancellables)
    }

    private func handleKeyboard(notification: Notification, visible: Bool) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else { return }

        let screenSize = UIScreen.main.bounds.size
        let isActuallyVisible = visible && keyboardFrame.origin.y < screenSize.height
        let height = isActuallyVisible ? (screenSize.height - keyboardFrame.origin.y) : 0
        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25

        withAnimation(.easeOut(duration: duration)) {
            keyboardHeight = height
            isKeyboardVisible = isActuallyVisible && height > 0
        }

        if isKeyboardVisible && height > 0 {
            updateWindow(height: height, duration: duration)
        } else {
            hideWindow(duration: duration)
        }
    }

    // MARK: - Window Management

    private func updateWindow(height: CGFloat, duration: Double) {
        if backdropWindow == nil { setupWindow() }
        guard let window = backdropWindow else { return }

        let screenSize = UIScreen.main.bounds.size
        let overscan: CGFloat = 40
        let frame = CGRect(
            x: 0,
            y: screenSize.height - height - overscan,
            width: screenSize.width,
            height: height + overscan + 100
        )

        window.isHidden = false
        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .curveEaseOut]) {
            window.frame = frame
            window.alpha = 1.0
        }
    }

    private func hideWindow(duration: Double = 0.25) {
        guard let window = backdropWindow else { return }
        if duration == 0 {
            window.alpha = 0
            window.frame.origin.y = UIScreen.main.bounds.height
            window.isHidden = true
            return
        }
        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .curveEaseIn], animations: {
            window.alpha = 0
            window.frame.origin.y = UIScreen.main.bounds.height
        }) { [weak self] _ in
            if self?.isKeyboardVisible == false {
                window.isHidden = true
            }
        }
    }

    private func setupWindow() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .compactMap({ $0 as? UIWindowScene })
            .first ?? (UIApplication.shared.connectedScenes.first as? UIWindowScene)
        else { return }

        let window = UIWindow(windowScene: windowScene)
        window.windowLevel = UIWindow.Level(rawValue: 1)
        window.isUserInteractionEnabled = false
        window.backgroundColor = .clear

        let controller = UIHostingController(rootView: GradientGlowBackdropView())
        controller.view.backgroundColor = .clear
        window.rootViewController = controller

        backdropWindow = window
    }
}

// MARK: - Gradient Glow Backdrop View

/// Animated gradient glow that renders behind the keyboard.
struct GradientGlowBackdropView: View {
    @State private var phase: CGFloat = 0
    @State private var floatingAnimation = false

    private let glowColors: [Color] = [
        Color(.systemIndigo).opacity(0.45),
        Color(.systemPurple).opacity(0.38),
        Color(.systemCyan).opacity(0.32),
        Color(.systemBlue).opacity(0.28)
    ]

    private let orbColors: [Color] = [
        .purple, .cyan, .blue, .indigo, .mint, .pink
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                animatedGradientLayer(time: time)
                orbLayer(time: time)
            }
            .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
            .offset(y: 40)
            .compositingGroup()
            .scaleEffect(1.1)
            .blur(radius: 12)
            .opacity(0.7)
            .allowsHitTesting(false)
        }
    }

    // MARK: - Animated Gradient

    @ViewBuilder
    private func animatedGradientLayer(time: TimeInterval) -> some View {
        let angle = Angle(degrees: time * 25)
        let startPoint = UnitPoint(
            x: 0.5 + 0.5 * cos(angle.radians),
            y: 0.5 + 0.5 * sin(angle.radians)
        )
        let endPoint = UnitPoint(
            x: 0.5 - 0.5 * cos(angle.radians),
            y: 0.5 - 0.5 * sin(angle.radians)
        )

        LinearGradient(
            colors: glowColors,
            startPoint: startPoint,
            endPoint: endPoint
        )
        .hueRotation(.degrees(time * 12))
        .saturation(1.2)
    }

    // MARK: - Floating Orbs

    @ViewBuilder
    private func orbLayer(time: TimeInterval) -> some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<4, id: \.self) { index in
                    orbView(for: index, in: geo.size, time: time)
                }
            }
        }
    }

    @ViewBuilder
    private func orbView(for index: Int, in size: CGSize, time: TimeInterval) -> some View {
        let color = orbColors[index % orbColors.count]
        let seed = Double(index)
        let orbSize: CGFloat = 120 + CGFloat(index) * 30

        let baseX = size.width * CGFloat(0.2 + 0.2 * Double(index))
        let baseY = size.height * 0.5
        let dx = sin(time * 0.8 + seed * 1.5) * 40
        let dy = cos(time * 0.6 + seed * 2.0) * 30

        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        color.opacity(0.5),
                        color.opacity(0.15),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: orbSize / 2
                )
            )
            .frame(width: orbSize, height: orbSize)
            .blur(radius: orbSize / 5)
            .position(x: baseX + dx, y: baseY + dy)
    }
}

// MARK: - View Modifier

struct KeyboardBackdropModifierV2: ViewModifier {
    @StateObject private var manager = KeyboardBackdropManager.shared

    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func withKeyboardGlowBackdrop() -> some View {
        modifier(KeyboardBackdropModifierV2())
    }
}
