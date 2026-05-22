import SwiftUI

struct Diag_DeadPixelDetectionView: View {
    @State private var currentColorIndex = 0
    @State private var showInstructions = true

    private let testColors: [(Color, String)] = [
        (.white, "White — look for dark spots"),
        (.black, "Black — look for bright spots"),
        (.red, "Red — check for missing red sub-pixels"),
        (.green, "Green — check for missing green sub-pixels"),
        (.blue, "Blue — check for missing blue sub-pixels"),
    ]

    var body: some View {
        ZStack {
            testColors[currentColorIndex].0
                .ignoresSafeArea()
                .onTapGesture {
                    if showInstructions {
                        showInstructions = false
                    } else {
                        currentColorIndex = (currentColorIndex + 1) % testColors.count
                    }
                }

            if showInstructions {
                VStack(spacing: 16) {
                    Image(systemName: "eye.fill")
                        .font(.largeTitle)
                    Text("Dead Pixel Detection")
                        .font(.title2.bold())
                    Text("Tap anywhere to cycle through solid colors.\nLook carefully for any pixels that don't match the background color.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                    Text("Tap to begin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(30)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .padding()
            } else {
                VStack {
                    Spacer()
                    Text(testColors[currentColorIndex].1)
                        .font(.caption)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Dead Pixel Detection")
        .navigationBarTitleDisplayMode(.inline)
    }
}
