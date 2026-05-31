import SwiftUI

struct DeveloperLocalizationManagerView: View {
    @ObservedObject var locService = LocalizationService.shared
    @ObservedObject var appService = DeveloperAppService.shared

    @State private var selectedAppID: UUID?
    @State private var showingAddLocale = false
    @State private var newLocaleCode = ""
    @State private var newLocaleName = ""

    var locales: [LocalizationLocale] {
        locService.locales.filter { $0.appID == selectedAppID }
    }

    var body: some View {
        List {
            Section("Translation Scope") {
                Picker("App", selection: $selectedAppID) {
                    Text("Select App").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            if selectedAppID != nil {
                Section("Active Locales") {
                    if locales.isEmpty {
                        EmptyStateView(icon: "character.book.closed", title: "No Localizations", message: "Register a target language to start localized string management.")
                    } else {
                        ForEach(locales) { locale in
                            localeRow(locale)
                        }
                    }
                }

                Section("Lifecycle") {
                    Button { showingAddLocale = true } label: { Label("Add Target Language", systemImage: "plus.circle.fill").font(.subheadline.bold()) }
                    Button { syncTranslations() } label: { Label("Sync Translations", systemImage: "arrow.triangle.2.circlepath").font(.subheadline.bold()) }
                }
            }
        }
        .navigationTitle("Localization")
        .sheet(isPresented: $showingAddLocale) { addLocaleSheet }
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
        }
    }

    private func localeRow(_ locale: LocalizationLocale) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(locale.name).font(.subheadline.bold())
                Text(locale.code.uppercased()).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(locale.completionPercentage * 100))%").font(.system(size: 10, weight: .black))
                ProgressView(value: locale.completionPercentage).tint(.green).frame(width: 60)
            }
        }
        .padding(.vertical, 4)
    }

    private var addLocaleSheet: some View {
        NavigationStack {
            Form {
                Section("Locale Configuration") {
                    TextField("ISO Code", text: $newLocaleCode, prompt: Text("e.g. de-DE"))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("Display Name", text: $newLocaleName, prompt: Text("e.g. German"))
                }
            }
            .navigationTitle("New Locale")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddLocale = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addLocale() }
                        .disabled(newLocaleCode.isEmpty || newLocaleName.isEmpty)
                }
            }
        }
    }

    private func addLocale() {
        guard let appID = selectedAppID else { return }
        let locale = LocalizationLocale(appID: appID, code: newLocaleCode, name: newLocaleName)
        Task {
            try? await locService.addLocale(locale)
            await MainActor.run {
                showingAddLocale = false
                newLocaleCode = ""
                newLocaleName = ""
            }
        }
    }

    private func syncTranslations() {
        guard let appID = selectedAppID else { return }
        Task { try? await locService.syncTranslations(appID: appID) }
    }
}
