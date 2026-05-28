import SwiftUI

struct MarketplaceSubmissionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentStep = 1

    // Step 1: Type Selection
    @State private var selectedType: AppType = .app

    // Step 2: Basic Metadata
    @State private var appName = ""
    @State private var subtitle = ""
    @State private var description = ""

    // Step 3: Media
    @State private var screenshotsCount = 0

    // Step 4: Technical
    @State private var versionNumber = "1.0.0"

    // Step 5: Scopes
    @State private var selectedScopes: Set<String> = []

    var body: some View {
        VStack {
            stepIndicator

                ScrollView {
                    VStack(spacing: 24) {
                        if currentStep == 1 {
                            typeSelectionStep
                        } else if currentStep == 2 {
                            basicMetadataStep
                        } else if currentStep == 3 {
                            mediaAssetsStep
                        } else if currentStep == 4 {
                            technicalDetailsStep
                        } else if currentStep == 5 {
                            scopeDeclarationStep
                        } else if currentStep == 6 {
                            pricingLicensingStep
                        } else if currentStep == 7 {
                            dataHandlingStep
                        } else {
                            reviewSubmitStep
                        }
                    }
                    .padding()
                }

                footer
            }
        .navigationTitle("New Submission")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save Draft") { /* Save */ }
                    .font(.subheadline)
            }
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 4) {
            ForEach(1...8, id: \.self) { step in
                Rectangle()
                    .fill(step <= currentStep ? Color.accentColor : Color.secondary.opacity(0.2))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal)
    }

    private var typeSelectionStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What are you building?").font(.headline)
            ForEach(AppType.allCases, id: \.self) { type in
                Button { selectedType = type } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(type.rawValue).font(.subheadline.bold())
                            Text("Brief description of what a \(type.rawValue) is.").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selectedType == type {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.blue)
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(selectedType == type ? Color.blue : Color.clear, lineWidth: 2))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var basicMetadataStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information").font(.headline)
            TextField("App Name", text: $appName).textFieldStyle(.roundedBorder)
            TextField("Subtitle", text: $subtitle).textFieldStyle(.roundedBorder)
            TextEditor(text: $description)
                .frame(height: 150)
                .padding(4)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
        }
    }

    private var mediaAssetsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Media Assets").font(.headline)

            HStack {
                VStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(Image(systemName: "plus").foregroundStyle(.secondary))
                    Text("App Icon").font(.caption2)
                }
                .frame(width: 80)
                Spacer()
            }

            Text("Screenshots (Min 3)").font(.subheadline.bold())
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.1))
                            .frame(width: 120, height: 200)
                            .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                    }
                }
            }
        }
    }

    private var technicalDetailsStep: some View {
        Form {
            TextField("Version Number", text: $versionNumber)
            TextField("Min SDK Version", text: .constant("2.0.0"))
            Toggle("Supports Desktop", isOn: .constant(true))
            Toggle("Supports Mobile", isOn: .constant(true))
        }
        .frame(height: 250)
    }

    private var scopeDeclarationStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Declare Scopes").font(.headline)
            Text("Identify all permissions your app requires.").font(.caption).foregroundStyle(.secondary)

            ForEach(["read:user", "read:data", "write:data"], id: \.self) { scope in
                Toggle(scope, isOn: .constant(false))
            }
        }
    }

    private var pricingLicensingStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pricing & Licensing").font(.headline)
            Picker("Model", selection: .constant(0)) {
                Text("Free").tag(0)
                Text("Paid").tag(1)
                Text("Freemium").tag(2)
            }
            .pickerStyle(.segmented)

            TextField("License URL", text: .constant(""))
                .textFieldStyle(.roundedBorder)
        }
    }

    private var dataHandlingStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Handling").font(.headline)
            Toggle("Does this app collect user data?", isOn: .constant(true))
            Toggle("Is data shared with 3rd parties?", isOn: .constant(false))
            TextField("Privacy Policy URL", text: .constant(""))
                .textFieldStyle(.roundedBorder)
        }
    }

    private var reviewSubmitStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Review Submission").font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                summaryRow(label: "Name", value: appName)
                summaryRow(label: "Type", value: selectedType.rawValue)
                summaryRow(label: "Version", value: versionNumber)
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Label("I certify that all information provided is accurate and complies with platform policies.", systemImage: "checkmark.square")
                .font(.caption)
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).bold()
        }
        .font(.subheadline)
    }

    private var footer: some View {
        HStack {
            if currentStep > 1 {
                Button("Back") { currentStep -= 1 }
                    .buttonStyle(.bordered)
            }
            Spacer()
            Button(currentStep == 8 ? "Submit for Review" : "Next") {
                if currentStep < 8 {
                    currentStep += 1
                } else {
                    dismiss()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
