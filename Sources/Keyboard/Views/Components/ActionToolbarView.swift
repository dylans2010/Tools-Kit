import SwiftUI

struct ActionToolbarView: View {
    @Binding var state: KeyboardState
    var proxyManager: TextProxyManager

    var body: some View {
        HStack {
            actionButton(title: "Fix Grammar", icon: "checkmark.circle") {
                Task {
                    let fixed = await KeyboardAIService.shared.applyTransformation(text: state.currentText, style: .standard)
                    proxyManager.updateProxy(with: fixed)
                }
            }

            actionButton(title: "Shorten", icon: "arrow.left.and.right.righttriangle.left.righttriangle.right") {
                Task {
                    let shortened = await KeyboardAIService.shared.applyTransformation(text: state.currentText, style: .concise)
                    proxyManager.updateProxy(with: shortened)
                }
            }

            actionButton(title: "Convert", icon: "arrow.2.squarepath") {
                Task {
                    let converted = await KeyboardAIService.shared.convertContent(text: state.currentText, type: .list)
                    proxyManager.updateProxy(with: converted)
                }
            }

            Spacer()

            if state.isLoading {
                ProgressView()
                    .padding(.trailing)
            }
        }
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                Text(title)
                    .font(.caption2)
            }
            .padding(.horizontal, 10)
        }
    }
}
