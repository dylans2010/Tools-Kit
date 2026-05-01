import SwiftUI

struct AutoEditView: View {
    @StateObject private var manager = AutoEditManager.shared
    @State private var selectedPresetID: UUID?
    @State private var isAssembling = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Auto Edit Assembly")
                .font(.title2.bold())

            Text("Select a style to automatically assemble your video using the best parts of your clips.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(manager.presets) { preset in
                    PresetRow(preset: preset, isSelected: selectedPresetID == preset.id)
                        .onTapGesture { selectedPresetID = preset.id }
                }
            }
            .padding(.horizontal)

            Spacer()

            Button(action: assemble) {
                if isAssembling {
                    ProgressView().tint(.white)
                } else {
                    Text("Assemble Video")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedPresetID == nil || isAssembling)
            .padding()
        }
        .padding(.top)
    }

    private func assemble() {
        isAssembling = true
        // Simulate assembly
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isAssembling = false
            // Navigate to new project
        }
    }
}

struct PresetRow: View {
    let preset: AutoEditPreset
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(preset.name).font(.headline)
                Text("\(preset.style.rawValue.capitalized) • \(preset.pacing.rawValue.capitalized) Pacing")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.workspaceSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}
