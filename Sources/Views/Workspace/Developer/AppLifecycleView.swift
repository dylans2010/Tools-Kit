import SwiftUI

struct AppLifecycleView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            Picker("App", selection: $selectedAppID) {
                ForEach(appService.apps) { app in
                    Text(app.name).tag(Optional(app.id))
                }
            }
            .padding()

            if let appID = selectedAppID, let app = appService.apps.first(where: { $0.id == appID }) {
                List {
                    Section("Global Status") {
                        HStack {
                            Text("Current State")
                            Spacer()
                            Text(app.status.rawValue.uppercased())
                                .font(.caption.bold())
                                .foregroundStyle(.blue)
                        }
                    }

                    Section("Lifecycle Transitions") {
                        if app.status == .draft {
                            Button("Submit for Review") {
                                Task { try? await appService.transitionStatus(id: appID, newStatus: .underReview, reason: "Manual submission") }
                            }
                        }
                        if app.status == .live {
                            Button("Deprecate Application", role: .destructive) {
                                Task { try? await appService.transitionStatus(id: appID, newStatus: .deprecated, reason: "App version end of life") }
                            }
                            Button("Archive Application", role: .destructive) {
                                Task { try? await appService.transitionStatus(id: appID, newStatus: .archived, reason: "Project discontinued") }
                            }
                        }
                    }
                }
            } else {
                EmptyStateView(icon: "arrow.clockwise.circle", title: "Select App", message: "Select an application to manage its lifecycle.")
            }
        }
        .navigationTitle("App Lifecycle")
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
        }
    }
}
