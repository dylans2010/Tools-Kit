import SwiftUI

struct DeveloperMonetizationView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?
    @State private var showingEditPricing = false
    @State private var amount = ""
    @State private var selectedModel: MonetizationModel = .free

    var selectedApp: DeveloperApp? {
        appService.apps.first { $0.id == selectedAppID }
    }

    var body: some View {
        List {
            Section("Management Scope") {
                Picker("App", selection: $selectedAppID) {
                    Text("Select an App").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            if let app = selectedApp {
                Section("Financial Performance") {
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Lifetime Revenue").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
                            Text("$\(String(format: "%.2f", app.revenue))").font(.title3.bold())
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Model").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
                            Text(app.monetizationModel.rawValue).font(.subheadline.bold())
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Pricing Configuration") {
                    HStack {
                        Text("Current Price")
                        Spacer()
                        Text("$\(String(format: "%.2f", app.pricingConfig.amount)) \(app.pricingConfig.currency)")
                            .font(.subheadline.bold())
                    }

                    if let interval = app.pricingConfig.interval {
                        HStack {
                            Text("Billing Interval")
                            Spacer()
                            Text(interval.capitalized).font(.subheadline.bold())
                        }
                    }

                    Button {
                        amount = String(format: "%.2f", app.pricingConfig.amount)
                        selectedModel = app.monetizationModel
                        showingEditPricing = true
                    } label: {
                        Label("Update Pricing Model", systemImage: "pencil.circle.fill").font(.subheadline.bold())
                    }
                }

                Section("Payouts") {
                    HStack {
                        Image(systemName: "banknote.fill").foregroundStyle(.green)
                        Text("Connected Account").font(.subheadline)
                        Spacer()
                        Text("Verified").font(.caption.bold()).foregroundStyle(.green)
                    }
                }
            } else {
                EmptyStateView(icon: "dollarsign.circle", title: "Select an App", message: "Choose an application to manage its pricing strategy and revenue telemetry.")
            }
        }
        .navigationTitle("Monetization")
        .sheet(isPresented: $showingEditPricing) {
            NavigationStack {
                Form {
                    Section("Business Model") {
                        Picker("Model", selection: $selectedModel) {
                            ForEach(MonetizationModel.allCases, id: \.self) { model in
                                Text(model.rawValue).tag(model)
                            }
                        }
                    }

                    if selectedModel != .free {
                        Section("Price Details") {
                            TextField("Amount", text: $amount)
                                .keyboardType(.decimalPad)
                        }
                    }
                }
                .navigationTitle("Edit Pricing")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingEditPricing = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            updatePricing()
                        }
                    }
                }
            }
        }
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
        }
    }

    private func updatePricing() {
        guard var updatedApp = selectedApp else { return }
        updatedApp.monetizationModel = selectedModel
        updatedApp.pricingConfig.amount = Double(amount) ?? 0.0

        Task {
            try? await appService.updateApp(updatedApp)
            await MainActor.run { showingEditPricing = false }
        }
    }
}
