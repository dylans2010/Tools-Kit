import SwiftUI
import UIKit

struct Diag_InstalledFontsView: View {
    @State private var fontFamilies: [FontFamily] = []
    @State private var searchText: String = ""
    @State private var selectedFamily: FontFamily?

    struct FontFamily: Identifiable {
        let id = UUID()
        let name: String
        let fonts: [String]
    }

    var filteredFamilies: [FontFamily] {
        if searchText.isEmpty { return fontFamilies }
        let query = searchText.lowercased()
        return fontFamilies.filter {
            $0.name.lowercased().contains(query) ||
            $0.fonts.contains { $0.lowercased().contains(query) }
        }
    }

    var body: some View {
        Form {
            Section("Summary") {
                LabeledContent("Font Families") { Text("\(fontFamilies.count)") }
                LabeledContent("Total Fonts") {
                    Text("\(fontFamilies.reduce(0) { $0 + $1.fonts.count })")
                }
                LabeledContent("System Font") {
                    Text(UIFont.systemFont(ofSize: 17).familyName)
                }
            }

            Section("Search") {
                TextField("Search fonts...", text: $searchText)
                    .textInputAutocapitalization(.never)
            }

            Section("Families (\(filteredFamilies.count))") {
                ForEach(filteredFamilies) { family in
                    DisclosureGroup {
                        ForEach(family.fonts, id: \.self) { fontName in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(fontName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("The quick brown fox jumps over the lazy dog")
                                    .font(.custom(fontName, size: 14))
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 2)
                        }
                    } label: {
                        HStack {
                            Text(family.name)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(family.fonts.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Installed Fonts")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadFonts() }
    }

    private func loadFonts() {
        let families = UIFont.familyNames.sorted()
        fontFamilies = families.map { family in
            let fonts = UIFont.fontNames(forFamilyName: family).sorted()
            return FontFamily(name: family, fonts: fonts)
        }
    }
}
