import SwiftUI

struct FunnelBuilderView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var analyticsService = AnalyticsService.shared
    @State private var selectedAppID: UUID?
    @State private var showingCreator = false
    @State private var funnels: [FunnelDef] = [
        FunnelDef(name: "Registration Flow", steps: ["app_open", "landing_view", "email_submit", "verify_email"]),
        FunnelDef(name: "Purchase Conversion", steps: ["item_view", "add_to_cart", "checkout_start", "payment_complete"])
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                appSelector

                if let appID = selectedAppID {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Defined Funnels").font(.headline)

                        if funnels.isEmpty {
                            EmptyStateView(icon: "filter", title: "No Funnels", message: "Create a conversion funnel to visualize how users progress through key application flows.")
                        } else {
                            ForEach(funnels) { funnel in
                                funnelCard(funnel)
                            }
                        }
                    }
                    .padding()
                } else {
                    EmptyStateView(icon: "filter", title: "Select App", message: "Choose an application to manage its conversion funnels.")
                        .padding(.top, 40)
                }
            }
        }
        .navigationTitle("Funnels")
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
        }
        .toolbar {
            if selectedAppID != nil {
                Button { showingCreator = true } label: { Image(systemName: "plus.circle.fill") }
            }
        }
        .sheet(isPresented: $showingCreator) {
            NewFunnelSheet(appID: selectedAppID ?? UUID()) { newFunnel in
                funnels.insert(newFunnel, at: 0)
            }
        }
    }

    private var appSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Analysis Target").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
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

    private func funnelCard(_ funnel: FunnelDef) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(funnel.name).font(.subheadline.bold())
                    Text("\(funnel.steps.count) steps defined").font(.system(size: 9)).foregroundStyle(.secondary)
                }
                Spacer()
                Text("64% CV").font(.system(size: 10, weight: .black)).foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(0..<funnel.steps.count, id: \.self) { index in
                    let step = funnel.steps[index]
                    let val = 1.0 - (Double(index) * 0.2)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(index + 1). \(step)").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(val * 100))%").font(.system(size: 8, weight: .bold)).foregroundStyle(.tertiary)
                        }
                        ProgressView(value: val)
                            .progressViewStyle(.linear)
                            .tint(.blue.opacity(0.4 + (val * 0.6)))
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }
}

struct FunnelDef: Identifiable {
    let id = UUID()
    let name: String
    let steps: [String]
}

struct NewFunnelSheet: View {
    let appID: UUID
    var onSave: (FunnelDef) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var funnelName = ""
    @State private var steps: [String] = [""]

    var body: some View {
        NavigationStack {
            Form {
                Section("Funnel Identity") {
                    TextField("Name (e.g. Signup Flow)", text: $funnelName)
                }
                Section("Conversion Steps") {
                    ForEach(0..<steps.count, id: \.self) { i in
                        TextField("Event Name", text: $steps[i])
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    Button { steps.append("") } label: { Label("Add Step", systemImage: "plus.circle") }
                }
            }
            .navigationTitle("New Funnel")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let filteredSteps = steps.filter { !$0.isEmpty }
                        onSave(FunnelDef(name: funnelName, steps: filteredSteps))
                        dismiss()
                    }.disabled(funnelName.isEmpty || steps.filter({!$0.isEmpty}).count < 2)
                }
            }
        }
    }
}
