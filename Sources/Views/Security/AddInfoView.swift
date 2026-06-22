import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct AddInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vaultManager = VaultManager.shared
    @State private var category: VaultCategory = .credentials
    @State private var title = ""
    @State private var note = ""
    @State private var username = ""
    @State private var password = ""
    @State private var domain = ""
    @State private var showingFilePicker = false
    @State private var selectedFile: URL?
    @State private var documentType = "ID"
    @State private var expirationDate = Date()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var totpSecret = ""
    @State private var totpIssuer = ""
    @State private var totpAccount = ""
    @State private var totpCode = "------"
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var errorMessage: String?

    var body: some View { NavigationStack { formContent } }

    private var formContent: some View {
        Form {
            Section {
                Label("Add Secure Item", systemImage: "lock.doc")
                Text("Encrypted locally before being stored.").font(.caption).foregroundStyle(.secondary)
            }
            Section {
                Picker("Type", selection: $category) { ForEach(VaultCategory.allCases) { Label($0.rawValue, systemImage: $0.icon).tag($0) } }
                    .pickerStyle(.segmented)
                TextField("Title", text: $title)
            } header: {
                Text("Details")
            }
            dynamicSection
            Section { TextEditor(text: $note).frame(minHeight: 80) } header: {
                Text("Notes")
            }
            if let errorMessage { Section { Label(errorMessage, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) } }
        }
        .navigationTitle("New Entry")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("Save", action: saveItem).disabled(title.isEmpty) }
        }
        .sheet(isPresented: $showingFilePicker) { FileImporterView(allowedContentTypes: [.data, .item, .pdf], allowsMultipleSelection: false) { selectedFile = $0.first } }
        .onReceive(timer) { _ in if category == .totp && !totpSecret.isEmpty { updateTOTPCode() } }
    }

    @ViewBuilder private var dynamicSection: some View {
        switch category {
        case .credentials:
            Section { TextField("Username", text: $username); SecureField("Password", text: $password); TextField("Domain", text: $domain).autocapitalization(.none) } header: {
                Text("Credentials")
            }
        case .documents:
            Section { Picker("Type", selection: $documentType) { Text("ID").tag("ID"); Text("Passport").tag("Passport"); Text("Driver's License").tag("Driver's License"); Text("Insurance").tag("Insurance") }; DatePicker("Expiration", selection: $expirationDate, displayedComponents: .date); Button { showingFilePicker = true } label: { Label(selectedFile?.lastPathComponent ?? "Select Document", systemImage: "doc.badge.plus") } } header: {
                Text("Document")
            }
        case .photos:
            Section { PhotosPicker(selection: $selectedPhotoItem, matching: .images) { Label("Select Photo", systemImage: "photo.badge.plus") }.onChange(of: selectedPhotoItem) { _, item in Task { selectedPhotoData = try? await item?.loadTransferable(type: Data.self) } } } header: {
                Text("Photo")
            }
        case .files:
            Section { Button { showingFilePicker = true } label: { Label(selectedFile?.lastPathComponent ?? "Select File", systemImage: "folder.badge.plus") } } header: {
                Text("File")
            }
        case .totp:
            Section { TextField("Issuer", text: $totpIssuer); TextField("Account", text: $totpAccount); TextField("Secret", text: $totpSecret).autocapitalization(.none); LabeledContent(content: { Text(totpCode).font(.system(.title3, design: .monospaced).bold()).foregroundStyle(.blue) }, label: { Text("Live Code") }) } header: {
                Text("Authenticator")
            }
        }
    }

    private func updateTOTPCode() { if let code = TOTPService.shared.generateTOTP(secret: totpSecret) { totpCode = code } }
    private func saveItem() {
        errorMessage = nil
        do {
            let itemData: Data
            var metadata: [String: String] = [:]
            switch category {
            case .credentials:
                guard !username.isEmpty, !password.isEmpty else { errorMessage = "Username and password are required."; return }
                itemData = try JSONEncoder().encode(CredentialData(username: username, password: password, website: domain)); metadata = ["username": username, "domain": domain]
            case .documents:
                itemData = selectedFile != nil ? try Data(contentsOf: selectedFile!) : try JSONEncoder().encode(DocumentData(documentType: documentType, expirationDate: expirationDate)); metadata = ["documentType": documentType, "expiration": expirationDate.ISO8601Format()]
            case .photos:
                itemData = selectedPhotoData ?? Data(); metadata = ["type": "photo"]
            case .files:
                itemData = selectedFile != nil ? try Data(contentsOf: selectedFile!) : Data(); metadata = ["filename": selectedFile?.lastPathComponent ?? "unknown"]
            case .totp:
                guard !totpSecret.isEmpty else { errorMessage = "TOTP secret is required."; return }
                itemData = try JSONEncoder().encode(TOTPData(secret: totpSecret, issuer: totpIssuer, account: totpAccount)); metadata = ["issuer": totpIssuer, "account": totpAccount]
            }
            try vaultManager.addItem(VaultItem(category: category, title: title, note: note, payloadIdentifier: "", metadata: metadata), data: itemData)
            dismiss()
        } catch { errorMessage = "Failed to save vault item: \(error.localizedDescription)" }
    }
}
