import SwiftUI

struct DataHandlingPolicyBuilderView: View {
    @State private var currentStep = 0
    @State private var retentionPeriod = 30
    @State private var encryptionStandard = "AES-256"
    @State private var dataTypes: Set<String> = []
    @State private var deletionPolicy = "Immediate"
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            stepIndicator

            TabView(selection: $currentStep) {
                classificationStep.tag(0)
                retentionStep.tag(1)
                securityStep.tag(2)
                reviewStep.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            footer
        }
        .navigationTitle("Policy Builder")
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var stepIndicator: some View {
        HStack {
            ForEach(0..<4) { i in
                Circle()
                    .fill(i <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                if i < 3 {
                    Rectangle().fill(i < currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(height: 2)
                }
            }
        }
        .padding()
    }

    private var classificationStep: some View {
        List {
            Section("Data Classification") {
                Text("Select the types of data your application handles.").font(.caption).foregroundStyle(.secondary)
                toggleRow("User Profiles", id: "profiles")
                toggleRow("Location Data", id: "location")
                toggleRow("Financial Records", id: "financial")
                toggleRow("System Logs", id: "logs")
                toggleRow("Device Identifiers", id: "device")
            }
        }
    }

    private func toggleRow(_ title: String, id: String) -> some View {
        Toggle(title, isOn: Binding(
            get: { dataTypes.contains(id) },
            set: { val in
                if val { dataTypes.insert(id) }
                else { dataTypes.remove(id) }
            }
        ))
    }

    private var retentionStep: some View {
        Form {
            Section("Retention & Deletion") {
                Stepper("Retention Period: \(retentionPeriod) days", value: $retentionPeriod, in: 1...3650)

                Picker("Deletion Policy", selection: $deletionPolicy) {
                    Text("Immediate").tag("Immediate")
                    Text("7-day Grace Period").tag("Grace7")
                    Text("30-day Soft Delete").tag("Soft30")
                }
            }
        }
    }

    private var securityStep: some View {
        Form {
            Section("Security Standards") {
                Picker("Encryption at Rest", selection: $encryptionStandard) {
                    Text("AES-256").tag("AES-256")
                    Text("ChaCha20").tag("ChaCha20")
                    Text("RSA-4096").tag("RSA-4096")
                }

                Toggle("Enable Hardware Security Module (HSM)", isOn: .constant(true))
                Toggle("Audit All Data Access", isOn: .constant(true))
            }
        }
    }

    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Policy Summary").font(.headline)

                VStack(alignment: .leading, spacing: 12) {
                    summaryRow(label: "Data Types", value: "\(dataTypes.count) categories")
                    summaryRow(label: "Retention", value: "\(retentionPeriod) days")
                    summaryRow(label: "Encryption", value: encryptionStandard)
                    summaryRow(label: "Deletion", value: deletionPolicy)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    // save policy
                    dismiss()
                } label: {
                    Text("Generate & Apply Policy")
                        .font(.headline).frame(maxWidth: .infinity).padding()
                        .background(Color.accentColor).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).bold()
        }
    }

    private var footer: some View {
        HStack {
            if currentStep > 0 {
                Button("Back") { currentStep -= 1 }.buttonStyle(.bordered)
            }
            Spacer()
            if currentStep < 3 {
                Button("Next") { currentStep += 1 }.buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
