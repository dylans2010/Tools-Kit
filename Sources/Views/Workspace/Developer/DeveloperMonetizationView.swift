import SwiftUI

struct DeveloperMonetizationView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?

    var selectedApp: DeveloperApp? {
        appService.apps.first { $0.id == selectedAppID }
    }

    var body: some View {
        List {
            Section {
                Picker("App", selection: $selectedAppID) {
                    Text("Select an App").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            if let app = selectedApp {
                Section("Revenue Overview") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Revenue").font(.caption).foregroundStyle(.secondary)
                            Text("$\(String(format: "%.2f", app.revenue))").font(.title2.bold())
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Pricing Model").font(.caption).foregroundStyle(.secondary)
                            Text(app.monetizationModel.rawValue).font(.headline)
                        }
                    }
                }

                Section("Pricing Configuration") {
                    HStack {
                        Text("Price")
                        Spacer()
                        Text("$\(String(format: "%.2f", app.pricingConfig.amount)) \(app.pricingConfig.currency)")
                    }
                    if let interval = app.pricingConfig.interval {
                        HStack {
                            Text("Interval")
                            Spacer()
                            Text(interval.capitalized)
                        }
                    }
                }
            } else {
                Text("Select an app to view monetization details.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Monetization")
    }
}
