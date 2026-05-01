import SwiftUI

struct TimelineIntelligenceView: View {
    @StateObject private var service = TimelineIntelligenceService.shared
    @State private var isAnalyzing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles.tv")
                    .foregroundColor(.purple)
                Text("Timeline Intelligence").font(.headline)
                Spacer()
                if isAnalyzing {
                    ProgressView().controlSize(.small)
                }
            }

            if service.activeSuggestions.isEmpty && !isAnalyzing {
                Button("Run Analysis") { performAnalysis() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(service.activeSuggestions) { suggestion in
                        SuggestionRow(suggestion: suggestion)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func performAnalysis() {
        isAnalyzing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            service.activeSuggestions = [
                TimelineSuggestion(timestamp: 4.5, type: .cut, message: "Suggest cut here to match drum peak."),
                TimelineSuggestion(timestamp: 12.0, type: .paceAdjustment, message: "Scene duration is too long for current pacing.")
            ]
            isAnalyzing = false
        }
    }
}

struct SuggestionRow: View {
    let suggestion: TimelineSuggestion

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(suggestion.type.rawValue.capitalized).font(.caption.bold())
                Text(suggestion.message).font(.system(size: 11))
            }
            Spacer()
            Button("Apply") { }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }
}
