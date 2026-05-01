import SwiftUI

struct AIEditingPanelView: View {
    @State private var prompt = ""
    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("AI Editing Tools")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 12) {
                TextField("Background prompt...", text: $prompt)
                    .textFieldStyle(.roundedBorder)

                Button(action: { /* Trigger gen */ }) {
                    if isProcessing {
                        ProgressView()
                    } else {
                        Text("Generate Background")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }

            Divider()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                AIToolButton(icon: "person.badge.minus", label: "Remove Object")
                AIToolButton(icon: "camera.filters", label: "Auto Grade")
                AIToolButton(icon: "aspectratio", label: "Smart Crop")
                AIToolButton(icon: "wand.and.stars", label: "Enhance")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct AIToolButton: View {
    let icon: String
    let label: String

    var body: some View {
        Button(action: {}) {
            VStack {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
