import SwiftUI

struct AFMModelSelectionView: View {
    @StateObject private var modelManager = AFMModelManager.shared
    @ObservedObject var settingsManager = AIChatSettingsManager.shared

    var body: some View {
        VStack(spacing: 10) {
            ForEach(modelManager.availableModels, id: \.self) { model in
                Button(action: {
                    settingsManager.settings.selectedAFMModelID = model
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(model)
                                .font(.subheadline.bold())
                            Text(model.contains("Advanced") ? "Optimized for M-series" : "Optimized for efficiency")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if settingsManager.settings.selectedAFMModelID == model {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
    }
}
