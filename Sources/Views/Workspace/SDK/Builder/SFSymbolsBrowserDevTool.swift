import SwiftUI

struct SFSymbolsBrowserDevTool: DevTool {
    let id = "sf-symbols-browser"
    let name = "SF Symbols Browser"
    let category = DevToolCategory.uiDesign
    let icon = "square.grid.2x2"
    let description = "Browse and search Apple SF Symbols"

    func render() -> some View {
        SFSymbolsBrowserView()
    }
}

struct SFSymbolsBrowserView: View {
    @StateObject private var viewModel = SFSymbolsBrowserViewModel()
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "SF Symbols Browser",
                description: "Quickly find and preview system icons for your application UI.",
                icon: "square.grid.2x2"
            )
            .padding()

            VStack {
                TextField("Search symbols...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 20) {
                        ForEach(filteredSymbols, id: \.self) { symbol in
                            VStack {
                                Image(systemName: symbol)
                                    .font(.title)
                                    .frame(width: 40, height: 40)
                                Text(symbol)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .foregroundStyle(.secondary)
                            }
                            .onTapGesture {
                                UIPasteboard.general.string = symbol
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private var filteredSymbols: [String] {
        if searchText.isEmpty { return viewModel.commonSymbols }
        return viewModel.commonSymbols.filter { $0.contains(searchText.lowercased()) }
    }
}

class SFSymbolsBrowserViewModel: ObservableObject {
    // A subset of common symbols for browsing
    let commonSymbols = [
        "hammer.fill", "gear", "network", "wifi", "lock.fill", "person.fill",
        "house.fill", "magnifyingglass", "circle.fill", "square.fill",
        "star.fill", "heart.fill", "envelope.fill", "phone.fill",
        "camera.fill", "video.fill", "bubble.left.fill", "cloud.fill"
    ]
}
