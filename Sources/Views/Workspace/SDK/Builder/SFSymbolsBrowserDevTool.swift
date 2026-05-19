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
    @State private var selectedSymbol: String?
    @State private var symbolColor: Color = .primary
    @State private var symbolSize: Double = 30

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 16) {
                    ForEach(filteredSymbols, id: \.self) { symbol in
                        SymbolCell(
                            name: symbol,
                            color: symbolColor,
                            isSelected: selectedSymbol == symbol
                        )
                        .onTapGesture {
                            selectedSymbol = symbol
                            UIPasteboard.general.string = symbol
                        }
                    }
                }
                .padding()
            }

            if let selected = selectedSymbol {
                inspectorPanel(selected)
                    .transition(.move(edge: .bottom))
            }
        }
        .navigationTitle("SF Symbols")
        .animation(.spring(response: 0.3), value: selectedSymbol)
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search 100+ symbols...", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.categories, id: \.self) { cat in
                        Button {
                            viewModel.selectedCategory = cat
                        } label: {
                            Text(cat)
                                .font(.caption2.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(viewModel.selectedCategory == cat ? Color.blue : Color(.secondarySystemBackground))
                                .foregroundStyle(viewModel.selectedCategory == cat ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private func inspectorPanel(_ symbol: String) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text(symbol).font(.headline)
                    Text("Copied to clipboard").font(.caption).foregroundStyle(.green)
                }
                Spacer()
                Button { selectedSymbol = nil } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary).font(.title3)
                }
            }

            HStack(spacing: 20) {
                Image(systemName: symbol)
                    .font(.system(size: symbolSize))
                    .foregroundStyle(symbolColor)
                    .frame(width: 80, height: 80)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                VStack(spacing: 12) {
                    ColorPicker("Tint", selection: $symbolColor)
                        .font(.caption)

                    HStack {
                        Image(systemName: "minus").font(.caption)
                        Slider(value: $symbolSize, in: 20...60)
                        Image(systemName: "plus").font(.caption)
                    }
                }
            }

            HStack {
                codeSnippetView(label: "SwiftUI", code: "Image(systemName: \"\(symbol)\")")
                codeSnippetView(label: "UIKit", code: "UIImage(systemName: \"\(symbol)\")")
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Divider() }
    }

    private func codeSnippetView(label: String, code: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
            Text(code)
                .font(.system(size: 9, design: .monospaced))
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 4))
        }
    }

    private var filteredSymbols: [String] {
        let base = viewModel.selectedCategory == "All" ? viewModel.commonSymbols : viewModel.symbolMap[viewModel.selectedCategory] ?? []
        if searchText.isEmpty { return base }
        return base.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
}

struct SymbolCell: View {
    let name: String
    let color: Color
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: name)
                .font(.title2)
                .foregroundStyle(isSelected ? .white : color)
                .frame(width: 50, height: 50)
                .background(isSelected ? Color.blue : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.gray.opacity(0.1), lineWidth: 1))

            Text(name)
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

class SFSymbolsBrowserViewModel: ObservableObject {
    @Published var selectedCategory = "All"

    let categories = ["All", "Communication", "Devices", "Connectivity", "Media", "Objects", "Design"]

    let commonSymbols = [
        "hammer.fill", "gear", "network", "wifi", "lock.fill", "person.fill",
        "house.fill", "magnifyingglass", "circle.fill", "square.fill",
        "star.fill", "heart.fill", "envelope.fill", "phone.fill",
        "camera.fill", "video.fill", "bubble.left.fill", "cloud.fill",
        "bolt.fill", "leaf.fill", "sun.max.fill", "moon.fill", "archivebox.fill",
        "folder.fill", "paperplane.fill", "tray.full.fill", "calendar", "clock.fill",
        "alarm.fill", "stopwatch.fill", "timer", "gamecontroller.fill", "keyboard"
    ]

    let symbolMap: [String: [String]] = [
        "Communication": ["bubble.left.fill", "bubble.right.fill", "message.fill", "envelope.fill", "phone.fill", "video.fill"],
        "Devices": ["iphone", "ipad", "macbook", "applewatch", "display", "keyboard", "printer.fill", "scanner.fill"],
        "Connectivity": ["network", "wifi", "bolt.horizontal.icloud.fill", "antenna.radiowaves.left.and.right", "link", "externaldrive.fill"],
        "Media": ["play.fill", "pause.fill", "stop.fill", "backward.fill", "forward.fill", "record.circle", "music.note"],
        "Objects": ["hammer.fill", "gear", "lock.fill", "house.fill", "archivebox.fill", "folder.fill", "bin.xmark.fill"],
        "Design": ["pencil", "paintbrush.fill", "eyedropper", "square.grid.2x2", "circles.hexagonpath", "square.dashed"]
    ]
}

#Preview {
    SFSymbolsBrowserView()
}
