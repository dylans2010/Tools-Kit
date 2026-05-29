import SwiftUI

struct DocumentationLocalizationView: View {
    @ObservedObject var docService = DocumentationService.shared

    var body: some View {
        List {
            Section("Translation Status") {
                if docService.pages.isEmpty {
                    Text("No pages to translate.").foregroundStyle(.secondary)
                } else {
                    ForEach(docService.pages) { page in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(page.title).font(.headline)
                            HStack {
                                ForEach(page.translations, id: \.localeCode) { trans in
                                    Text(trans.localeCode.uppercased())
                                        .font(.system(size: 8, weight: .bold))
                                        .padding(4)
                                        .background(trans.isUpToDate ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                                        .foregroundStyle(trans.isUpToDate ? .green : .orange)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Localization")
    }
}
