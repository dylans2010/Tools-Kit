import SwiftUI

struct SFSymbolsBrowserDevTool: DevTool {
    let id = "sf-symbols-browser"
    let name = "SF Symbols Browser"
    let category = DevToolCategory.uiDesign
    let icon = "star.fill"
    let description = "Browse common SF Symbols"

    func render() -> some View {
        SFSymbolsBrowserView()
    }
}

struct SFSymbolsBrowserView: View {
    @State private var searchText = ""

    let symbols = [
        "square.and.arrow.up", "square.and.pencil", "pencil", "pencil.circle", "pencil.tip",
        "trash", "folder", "paperplane", "tray", "archivebox", "doc", "doc.text", "note.text",
        "calendar", "book", "bookmark", "paperclip", "link", "personalhotspot", "network",
        "hammer", "gear", "ladybug", "wrench.adjustable", "screwdriver", "bolt", "leaf",
        "heart", "star", "flag", "bell", "tag", "camera", "envelope", "gearshape",
        "house", "lock", "magnifyingglass", "person", "phone", "video", "waveform"
    ]

    var filteredSymbols: [String] {
        if searchText.isEmpty { return symbols }
        return symbols.filter { $0.contains(searchText.lowercased()) }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 20) {
                ForEach(filteredSymbols, id: \.self) { symbol in
                    VStack {
                        Image(systemName: symbol)
                            .font(.largeTitle)
                            .frame(height: 50)
                        Text(symbol)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .onTapGesture {
                        UIPasteboard.general.string = symbol
                    }
                }
            }
            .padding()
        }
        .searchable(text: $searchText)
    }
}
