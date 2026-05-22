import SwiftUI

struct Diag_ReduceMotionView: View {
    @State private var reduceMotion = UIAccessibility.isReduceMotionEnabled
    @State private var reduceTransparency = UIAccessibility.isReduceTransparencyEnabled
    @State private var differentiateWithoutColor = UIAccessibility.shouldDifferentiateWithoutColor
    @State private var increaseContrast = UIAccessibility.isDarkerSystemColorsEnabled
    @State private var animationOffset: CGFloat = 0

    var body: some View {
        Form {
            Section("Motion Settings") {
                VStack(spacing: 12) {
                    Image(systemName: reduceMotion ? "figure.stand" : "figure.walk")
                        .font(.system(size: 50))
                        .foregroundStyle(reduceMotion ? .orange : .green)
                        .offset(x: reduceMotion ? 0 : animationOffset)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 1).repeatForever(autoreverses: true), value: animationOffset)
                        .onAppear { animationOffset = 20 }

                    Text(reduceMotion ? "Reduce Motion: ON" : "Reduce Motion: OFF")
                        .font(.title3.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Visual Settings") {
                HStack {
                    Text("Reduce Motion")
                    Spacer()
                    Image(systemName: reduceMotion ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(reduceMotion ? .green : .secondary)
                }
                HStack {
                    Text("Reduce Transparency")
                    Spacer()
                    Image(systemName: reduceTransparency ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(reduceTransparency ? .green : .secondary)
                }
                HStack {
                    Text("Differentiate Without Color")
                    Spacer()
                    Image(systemName: differentiateWithoutColor ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(differentiateWithoutColor ? .green : .secondary)
                }
                HStack {
                    Text("Increase Contrast")
                    Spacer()
                    Image(systemName: increaseContrast ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(increaseContrast ? .green : .secondary)
                }
            }

            Section("Animation Test") {
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                        .frame(width: 60, height: 60)
                        .offset(x: reduceMotion ? 0 : animationOffset * 3)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 1).repeatForever(autoreverses: true), value: animationOffset)

                    Text(reduceMotion ? "Animations disabled (Reduce Motion is on)" : "Animation is playing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            Section {
                Button("Refresh") {
                    reduceMotion = UIAccessibility.isReduceMotionEnabled
                    reduceTransparency = UIAccessibility.isReduceTransparencyEnabled
                    differentiateWithoutColor = UIAccessibility.shouldDifferentiateWithoutColor
                    increaseContrast = UIAccessibility.isDarkerSystemColorsEnabled
                }
            }
        }
        .navigationTitle("Reduce Motion")
        .navigationBarTitleDisplayMode(.inline)
    }
}
