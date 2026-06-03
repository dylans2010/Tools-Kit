import SwiftUI

struct LocalizationAuditView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared

    var body: some View {
        List {
            Section("Coverage Audit") {
                if store.localeAudits.isEmpty {
                    Text("No audit data available.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(store.localeAudits) { audit in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(audit.locale).font(.subheadline.bold())
                                Spacer()
                                Text("\(Int(audit.coverage * 100))%").font(.caption.bold())
                            }
                            ProgressView(value: audit.coverage)
                                .tint(audit.coverage == 1.0 ? .green : .orange)

                            if audit.missingKeys > 0 {
                                Text("\(audit.missingKeys) strings require translation.")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section {
                Button { } label: {
                    Label("Export Translation Keys", systemImage: "square.and.arrow.up")
                }
            }
        }
        .navigationTitle("Localization Audit")
        .onAppear {
            if store.localeAudits.isEmpty {
                store.saveLocaleAudits([
                    LocaleAudit(locale: "English (US)", coverage: 1.0, missingKeys: 0),
                    LocaleAudit(locale: "French (FR)", coverage: 0.85, missingKeys: 42),
                    LocaleAudit(locale: "Spanish (ES)", coverage: 0.92, missingKeys: 24)
                ])
            }
        }
    }
}
