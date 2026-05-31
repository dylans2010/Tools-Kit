import SwiftUI

struct DocumentationLocalizationView: View {
    @ObservedObject var localizationService = LocalizationService.shared
    @State private var selectedLanguage: String = "en"
    @State private var showingAddLanguage = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                progressDashboard

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Active Locales").font(.headline)
                        Spacer()
                        Button { showingAddLanguage = true } label: {
                            Image(systemName: "plus.circle.fill").font(.title3)
                        }
                    }

                    ForEach(localizationService.locales) { locale in
                        localeCard(locale)
                    }
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Localization")
        .sheet(isPresented: $showingAddLanguage) {
            addLanguageSheet
        }
    }

    private var progressDashboard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Global Coverage").font(.headline)

            HStack(spacing: 20) {
                coverageMetric(label: "Locales", value: "\(localizationService.locales.count)", color: .blue)
                coverageMetric(label: "Avg Completion", value: "\(Int(localizationService.overallProgress * 100))%", color: .green)
                coverageMetric(label: "Pending Keys", value: "\(localizationService.totalPendingKeys)", color: .orange)
            }

            ProgressView(value: localizationService.overallProgress)
                .tint(.green)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func coverageMetric(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.title3.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func localeCard(_ locale: LocalizationLocale) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(locale.flag).font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(locale.name).font(.subheadline.bold())
                    Text(locale.code.uppercased()).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(locale.progress * 100))%").font(.caption.bold())
            }

            ProgressView(value: locale.progress)
                .progressViewStyle(.linear)
                .tint(locale.progress == 1.0 ? .green : .blue)

            HStack {
                Text("\(locale.translatedKeys) / \(locale.totalKeys) keys translated").font(.system(size: 9)).foregroundStyle(.secondary)
                Spacer()
                NavigationLink(destination: LocaleEditorView(locale: locale)) {
                    Text("Translate").font(.system(size: 10, weight: .bold))
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05)))
    }

    private var addLanguageSheet: some View {
        NavigationStack {
            List {
                Section("Available Languages") {
                    Text("Spanish (ES)").onTapGesture { addLocale("es", name: "Spanish", flag: "🇪🇸") }
                    Text("French (FR)").onTapGesture { addLocale("fr", name: "French", flag: "🇫🇷") }
                    Text("German (DE)").onTapGesture { addLocale("de", name: "German", flag: "🇩🇪") }
                    Text("Japanese (JP)").onTapGesture { addLocale("ja", name: "Japanese", flag: "🇯🇵") }
                }
            }
            .navigationTitle("Add Locale")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddLanguage = false } }
            }
        }
    }

    private func addLocale(_ code: String, name: String, flag: String) {
        let newLocale = LocalizationLocale(code: code, name: name, flag: flag, translatedKeys: 0, totalKeys: 120)
        localizationService.addLocale(newLocale)
        showingAddLanguage = false
    }
}

struct LocaleEditorView: View {
    let locale: LocalizationLocale
    @ObservedObject var localizationService = LocalizationService.shared
    @State private var searchText = ""

    var body: some View {
        List {
            Section("Translation Interface") {
                TextField("Search keys...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Pending Translations") {
                ForEach(0..<5) { i in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("auth_login_welcome").font(.caption.monospaced()).foregroundStyle(.secondary)
                        Text("Welcome back to the portal!").font(.subheadline)
                        TextField("Translation", text: .constant(""))
                            .textFieldStyle(.roundedBorder)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("\(locale.name) Translation")
    }
}
