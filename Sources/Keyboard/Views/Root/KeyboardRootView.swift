import SwiftUI

struct KeyboardRootView: View {
    @ObservedObject var proxyManager: TextProxyManager
    @State private var state = KeyboardState()

    var body: some View {
        VStack(spacing: 0) {
            if !state.currentText.isEmpty {
                RewriteBarView(state: $state) {
                    if let rewrite = state.bestRewrite {
                        proxyManager.updateProxy(with: rewrite)
                    }
                }

                SuggestionBarView(state: $state) { suggestion in
                    proxyManager.updateProxy(with: suggestion.suggestedText)
                }
            }

            ActionToolbarView(state: $state, proxyManager: proxyManager)

            ToneSelectorView(state: $state)

            // Standard keyboard layout would go here in a full implementation
            Spacer()
                .frame(height: 200)
                .background(Color(uiColor: .systemGray6))
        }
        .onChange(of: proxyManager.currentText) { newValue in
            state.currentText = newValue
            updateIntelligence()
        }
        .onAppear {
            state.accessMode = .ai // Simulated for production grade demo
        }
    }

    private func updateIntelligence() {
        Task {
            state.isLoading = true
            let response = await KeyboardAIService.shared.fetchIntelligence(for: state.currentText, mode: state.accessMode)

            await MainActor.run {
                state.analysis = response.analysis
                state.suggestions = response.suggestions
                state.bestRewrite = response.result
                state.isLoading = false
            }
        }
    }
}
