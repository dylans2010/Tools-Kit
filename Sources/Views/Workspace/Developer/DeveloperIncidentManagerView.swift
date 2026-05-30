import SwiftUI

struct DeveloperIncidentManagerView: View {
    @ObservedObject var incidentService = IncidentService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?
    @State private var showingReportIncident = false
    @State private var newIncidentTitle = ""
    @State private var newIncidentDescription = ""
    @State private var selectedSeverity: IncidentSeverity = .medium

    var filteredIncidents: [Incident] {
        incidentService.incidents.filter { selectedAppID == nil || $0.appID == selectedAppID }
    }

    var body: some View {
        List {
            Section {
                Picker("App", selection: $selectedAppID) {
                    Text("All Projects").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Active Incidents") {
                if filteredIncidents.isEmpty {
                    EmptyStateView(icon: "shield.checkmark", title: "No Incidents", message: "All systems operational. No active incidents reported.")
                } else {
                    ForEach(filteredIncidents) { incident in
                        incidentRow(incident)
                    }
                }
            }
        }
        .navigationTitle("Incident Manager")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingReportIncident = true } label: { Image(systemName: "exclamationmark.triangle.fill") }
            }
        }
        .sheet(isPresented: $showingReportIncident) {
            reportIncidentSheet
        }
    }

    private func incidentRow(_ incident: Incident) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(incident.title).font(.subheadline.bold())
                Spacer()
                Text(incident.severity.rawValue).font(.system(size: 8, weight: .bold))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(severityColor(incident.severity).opacity(0.1))
                    .foregroundStyle(severityColor(incident.severity))
                    .clipShape(Capsule())
            }
            Text(incident.status.rawValue).font(.caption).foregroundStyle(.secondary)
            Text(incident.createdAt.formatted()).font(.system(size: 8)).foregroundStyle(.tertiary)
        }
    }

    private func severityColor(_ severity: IncidentSeverity) -> Color {
        switch severity {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }

    private var reportIncidentSheet: some View {
        NavigationStack {
            Form {
                Section("Incident Details") {
                    TextField("Title", text: $newIncidentTitle)
                    TextField("Description", text: $newIncidentDescription)
                    Picker("Severity", selection: $selectedSeverity) {
                        ForEach(IncidentSeverity.allCases, id: \.self) { severity in
                            Text(severity.rawValue).tag(severity)
                        }
                    }
                }
            }
            .navigationTitle("Report Incident")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingReportIncident = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Report") {
                        if let appID = selectedAppID {
                            let incident = Incident(appID: appID, title: newIncidentTitle, description: newIncidentDescription, severity: selectedSeverity)
                            Task {
                                try? await incidentService.reportIncident(incident)
                                await MainActor.run {
                                    showingReportIncident = false
                                    newIncidentTitle = ""
                                    newIncidentDescription = ""
                                }
                            }
                        }
                    }
                    .disabled(newIncidentTitle.isEmpty || selectedAppID == nil)
                }
            }
        }
    }
}
