import SwiftUI

struct SFSymbolsBrowserTool: DevTool {
    let id = UUID()
    let name = "SF Symbols Browser"
    let category: DevToolCategory = .uiDesign
    let icon = "star.square.on.square"
    let description = "Browse and search SF Symbols"
    func render() -> some View { SFSymbolsBrowserDevToolView() }
}

struct SFSymbolsBrowserDevToolView: View {
    @State private var searchText = ""
    @State private var selectedWeight: Font.Weight = .regular
    @State private var symbolSize: Double = 28

    private let symbols = [
        "star.fill", "heart.fill", "house.fill", "gearshape.fill", "person.fill",
        "bell.fill", "bookmark.fill", "tag.fill", "folder.fill", "trash.fill",
        "paperplane.fill", "doc.fill", "calendar", "clock.fill", "map.fill",
        "camera.fill", "photo.fill", "film", "music.note", "mic.fill",
        "phone.fill", "envelope.fill", "bubble.left.fill", "globe", "wifi",
        "lock.fill", "key.fill", "shield.fill", "eye.fill", "magnifyingglass",
        "link", "bolt.fill", "cloud.fill", "sun.max.fill", "moon.fill",
        "paintbrush.fill", "pencil", "hammer.fill", "wrench.fill", "scissors",
        "flag.fill", "pin.fill", "mappin", "chart.bar.fill", "chart.pie.fill",
        "arrow.up", "arrow.down", "arrow.left", "arrow.right", "checkmark.circle.fill",
        "xmark.circle.fill", "plus.circle.fill", "minus.circle.fill", "info.circle.fill",
        "exclamationmark.triangle.fill", "hand.thumbsup.fill", "hand.thumbsdown.fill",
        "square.and.arrow.up", "square.and.arrow.down", "terminal.fill",
        "cpu", "memorychip", "battery.100", "antenna.radiowaves.left.and.right",
        "app.fill", "apps.iphone", "desktopcomputer", "laptopcomputer"
    ]

    private var filtered: [String] {
        if searchText.isEmpty { return symbols }
        return symbols.filter { $0.lowercased().contains(searchText.lowercased()) }
    }

    var body: some View {
        Form {
            Section("Settings") {
                LabeledContent("Size: \(Int(symbolSize))") { Slider(value: $symbolSize, in: 14...60) }
            }
            Section("Symbols (\(filtered.count))") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                    ForEach(filtered, id: \.self) { name in
                        VStack(spacing: 4) {
                            Image(systemName: name)
                                .font(.system(size: symbolSize))
                                .foregroundStyle(.accent)
                            Text(name)
                                .font(.system(size: 8))
                                .lineLimit(1)
                                .foregroundStyle(.secondary)
                        }
                        .frame(minHeight: 60)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search symbols...")
        .navigationTitle("SF Symbols Browser")
    }
}
