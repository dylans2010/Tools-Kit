import SwiftUI

struct PluginGlobalOverlay: ViewModifier {
    @State private var showingPlugins = false

    func body(content: Content) -> some View {
        ZStack {
            content

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingPlugins = true }) {
                        Image(systemName: "puzzlepiece.extension.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.green.gradient)
                            .clipShape(Circle())
                            .shadow(radius: 4, y: 2)
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingPlugins) {
            NavigationStack {
                PluginsInstalledView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showingPlugins = false }
                        }
                    }
            }
        }
    }
}

extension View {
    func withPluginOverlay() -> some View {
        self.modifier(PluginGlobalOverlay())
    }
}
