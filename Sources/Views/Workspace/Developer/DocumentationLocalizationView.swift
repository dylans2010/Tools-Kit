import SwiftUI

struct DocumentationLocalizationView: View {
    @ObservedObject var locService = LocalizationService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?
    @State private var showingAddLocale = false

    var locales: [LocalizationLocale] {
        locService.locales.filter { $0.appID == selectedAppID }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                appSelector
                progressDashboard

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Active Locales").font(.headline)
                        Spacer()
                        Button { showingAddLocale = true } label: {
                            Image(systemName: "plus.circle.fill").font(.title3)
                        }
                    }

                    if locales.isEmpty && selectedAppID != nil {
                        EmptyStateView(icon: "character.book.closed", title: "No Locales", message: "Enable multi-language support for your documentation to reach more developers globally.")
                    } else {
                        ForEach(locales) { locale in
                            localeCard(locale)
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Doc Localization")
        .sheet(isPresented: $showingAddLocale) {
            addLocaleSheet
        }
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
        }
    }

    private var appSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Project").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
            Picker("App", selection: $selectedAppID) {
                ForEach(appService.apps) { app in
                    Text(app.name).tag(Optional(app.id))
                }
            }
            .pickerStyle(.menu)
            .padding(4)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .overlay(alignment: .bottom) { Divider() }
    }

    private var progressDashboard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Global Coverage").font(.headline)

            HStack(spacing: 20) {
                coverageMetric(label: "Locales", value: "\(locales.count)", color: .blue)
                let avg = locales.isEmpty ? 0 : locales.map({$0.completionPercentage}).reduce(0, +) / Double(locales.count)
                coverageMetric(label: "Completion", value: "\(Int(avg * 100))%", color: .green)
                coverageMetric(label: "Sync Status", value: "OK", color: .orange)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
        .padding()
    }

    private func coverageMetric(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.title3.bold()).foregroundStyle(color)
            Text(label).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func localeCard(_ locale: LocalizationLocale) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(locale.name).font(.subheadline.bold())
                    Text(locale.code.uppercased()).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(locale.completionPercentage * 100))%").font(.caption.bold())
            }

            ProgressView(value: locale.completionPercentage)
                .progressViewStyle(.linear)
                .tint(locale.completionPercentage == 1.0 ? .green : .blue)

            HStack {
                Text("Sync active").font(.system(size: 8)).foregroundStyle(.secondary)
                Spacer()
                NavigationLink(destination: Text("\(locale.name) Editor")) {
                    Text("Translate").font(.system(size: 10, weight: .bold))
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    private var addLocaleSheet: some View {
        NavigationStack {
            List {
                Section("Available Regions") {
                    localeOption(code: "es-ES", name: "Spanish")
                    localeOption(code: "fr-FR", name: "French")
                    localeOption(code: "de-DE", name: "German")
                    localeOption(code: "ja-JP", name: "Japanese")
                }
            }
            .navigationTitle("Add Language")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddLocale = false } }
            }
        }
    }

    private func localeOption(code: String, name: String) -> some View {
        Button {
            addLocale(code, name: name)
        } label: {
            HStack {
                Text(name).font(.subheadline)
                Spacer()
                Text(code).font(.caption.monospaced()).foregroundStyle(.secondary)
            }
        }
    }

    private func addLocale(_ code: String, name: String) {
        guard let appID = selectedAppID else { return }
        let newLocale = LocalizationLocale(appID: appID, code: code, name: name)
        Task {
            try? await locService.addLocale(newLocale)
            await MainActor.run { showingAddLocale = false }
        }
    }
}
