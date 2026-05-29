import SwiftUI

struct AppEnvironmentsView: View {
    let appID: UUID
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var keyService = APIKeyService.shared

    var app: DeveloperApp? {
        appService.apps.first { $0.id == appID }
    }

    var body: some View {
        List {
            if let app = app {
                ForEach(app.environments) { env in
                    Section(env.name) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Base URL").font(.caption.bold()).foregroundStyle(.secondary)
                            Text(env.apiBaseURL).font(.subheadline)

                            Divider().padding(.vertical, 4)

                            Text("Assigned Keys").font(.caption.bold()).foregroundStyle(.secondary)
                            if env.assignedKeyIDs.isEmpty {
                                Text("No keys assigned.").font(.caption).foregroundStyle(.secondary)
                            } else {
                                ForEach(env.assignedKeyIDs, id: \.self) { keyID in
                                    if let key = keyService.keys.first(where: { $0.id == keyID }) {
                                        HStack {
                                            Text(key.label).font(.caption.bold())
                                            Spacer()
                                            Text(key.maskedValue).font(.system(size: 8, design: .monospaced))
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle("Environments")
    }
}
