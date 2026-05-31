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
        NavigationLink(destination: LocalizationEditorView(locale: locale)) {
            HStack {
                Text(locale.flag).font(.title3)
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

struct LocalizationEditorView: View {
    let locale: LocalizationLocale
    @ObservedObject var locService = LocalizationService.shared
    @State private var searchText = ""
    @State private var showingAddKey = false
    @State private var newKey = ""

    var filteredKeys: [LocalizationKey] {
        locService.keys.filter { key in
            key.appID == locale.appID && (searchText.isEmpty || key.key.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        List {
            Section {
                TextField("Search keys...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Strings") {
                if filteredKeys.isEmpty {
                    Text("No localization keys found.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(filteredKeys) { key in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(key.key).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(.secondary)
                            TextField("Translation", text: Binding(
                                get: { key.translations[locale.code] ?? "" },
                                set: { newValue in
                                    updateTranslation(keyID: key.id, value: newValue)
                                }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("\(locale.name) (\(locale.code))")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddKey = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAddKey) {
            NavigationStack {
                Form {
                    TextField("Key Name", text: $newKey)
                }
                .navigationTitle("New Key")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddKey = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { addKey() }
                            .disabled(newKey.isEmpty)
                    }
                }
            }
        }
    }

    private func updateTranslation(keyID: UUID, value: String) {
        Task {
            try? await locService.updateString(keyID: keyID, localeCode: locale.code, value: value)
            if let appID = locale.appID {
                try? await locService.syncTranslations(appID: appID)
            }
        }
    }

    private func addKey() {
        guard let appID = locale.appID else { return }
        let key = LocalizationKey(appID: appID, key: newKey)
        Task {
            try? await locService.saveKey(key)
            await MainActor.run {
                showingAddKey = false
                newKey = ""
            }
            try? await locService.syncTranslations(appID: appID)
        }
    }
}
