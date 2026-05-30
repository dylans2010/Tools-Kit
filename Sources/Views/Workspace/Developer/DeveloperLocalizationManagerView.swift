import SwiftUI

struct DeveloperLocalizationManagerView: View {
    @ObservedObject var locService = LocalizationService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?

    var filteredKeys: [LocalizationKey] {
        locService.keys.filter { selectedAppID == nil || $0.appID == selectedAppID }
    }

    var body: some View {
        List {
            Section {
                Picker("App", selection: $selectedAppID) {
                    Text("All Projects").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Localization Keys") {
                if filteredKeys.isEmpty {
                    EmptyStateView(icon: "character.book.closed.fill", title: "No Translations", message: "Manage your application's localized strings and multi-language support.")
                } else {
                    ForEach(filteredKeys) { keyRecord in
                        VStack(alignment: .leading) {
                            Text(keyRecord.key).font(.subheadline.bold()).monospaced()
                            Text("\(keyRecord.translations.count) languages").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Localization")
    }
}
