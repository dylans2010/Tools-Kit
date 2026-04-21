import SwiftUI

struct ModernSheetLoadingView: View {
    let title: String
    let subtitle: String

    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black.opacity(0.9), Color.blue.opacity(0.35), Color.purple.opacity(0.45), Color.black.opacity(0.9)],
                startPoint: animate ? .topLeading : .bottomTrailing,
                endPoint: animate ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()

            ZStack {
                Circle()
                    .fill(.blue.opacity(0.3))
                    .frame(width: 280, height: 280)
                    .blur(radius: 18)
                    .offset(x: animate ? -30 : 30, y: animate ? -36 : 36)
                Circle()
                    .fill(.purple.opacity(0.32))
                    .frame(width: 240, height: 240)
                    .blur(radius: 18)
                    .offset(x: animate ? 30 : -30, y: animate ? 34 : -34)
            }

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 10)
                        .frame(width: 88, height: 88)
                    Circle()
                        .trim(from: 0.12, to: 0.86)
                        .stroke(
                            LinearGradient(colors: [.cyan, .blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: .init(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 88, height: 88)
                        .rotationEffect(.degrees(animate ? 360 : 0))
                }

                VStack(spacing: 8) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(28)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
            .padding(24)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
    }
}
