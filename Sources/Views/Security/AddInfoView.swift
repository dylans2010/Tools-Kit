import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct AddInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vaultManager = VaultManager.shared

    @State private var category: VaultCategory = .credentials
    @State private var title = ""
    @State private var note = ""

    // Credentials
    @State private var username = ""
    @State private var password = ""
    @State private var domain = ""

    // Document/File
    @State private var showingFilePicker = false
    @State private var selectedFile: URL?
    @State private var documentType = "ID"
    @State private var expirationDate = Date()

    // Photo
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?

    // TOTP
    @State private var totpSecret = ""
    @State private var totpIssuer = ""
    @State private var totpAccount = ""
    @State private var totpCode = "------"
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $category) {
                        ForEach(VaultCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField("Title", text: $title)
                }

                dynamicSection

                Section("Notes") {
                    TextEditor(text: $note)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingFilePicker) {
                FileImporterView(allowedContentTypes: [.data, .item, .pdf], allowsMultipleSelection: false) { urls in
                    selectedFile = urls.first
                }
            }
            .onReceive(timer) { _ in
                if category == .totp && !totpSecret.isEmpty {
                    updateTOTPCode()
                }
            }
        }
    }

    @ViewBuilder
    private var dynamicSection: some View {
        switch category {
        case .credentials:
            Section("Credentials") {
                TextField("Username", text: $username)
                    .textContentType(.username)
                SecureField("Password", text: $password)
                    .textContentType(.password)
                TextField("Domain", text: $domain)
                    .textContentType(.URL)
                    .autocapitalization(.none)
            }
        case .documents:
            Section("Document Details") {
                Picker("Document Type", selection: $documentType) {
                    Text("ID").tag("ID")
                    Text("Passport").tag("Passport")
                    Text("Driver's License").tag("Driver's License")
                    Text("Insurance").tag("Insurance")
                }
                DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)

                Button {
                    showingFilePicker = true
                } label: {
                    Label(selectedFile?.lastPathComponent ?? "Select Document", systemImage: "doc.badge.plus")
                }
            }
        case .photos:
            Section("Photo") {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    if let selectedPhotoData, let uiImage = UIImage(data: selectedPhotoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                    } else {
                        Label("Select Photo", systemImage: "photo.badge.plus")
                    }
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            selectedPhotoData = data
                        }
                    }
                }
            }
        case .files:
            Section("File") {
                Button {
                    showingFilePicker = true
                } label: {
                    Label(selectedFile?.lastPathComponent ?? "Select File", systemImage: "folder.badge.plus")
                }
            }
        case .totp:
            Section("TOTP Settings") {
                TextField("Issuer (e.g. Google)", text: $totpIssuer)
                TextField("Account (e.g. email@me.com)", text: $totpAccount)
                TextField("Secret Key", text: $totpSecret)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                HStack {
                    Text("Live Code:")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(totpCode)
                        .font(.system(.title3, design: .monospaced).bold())
                        .foregroundColor(.blue)
                }
            }
        }
    }

    private func updateTOTPCode() {
        if let code = TOTPService.shared.generateCode(secret: totpSecret) {
            totpCode = code
        }
    }

    private func saveItem() {
        let itemData: Data
        var metadata: [String: String] = [:]

        do {
            switch category {
            case .credentials:
                let data = CredentialData(username: username, password: password, website: domain)
                itemData = try JSONEncoder().encode(data)
                metadata["username"] = username
                metadata["domain"] = domain
            case .documents:
                let data = DocumentData(documentType: documentType, expirationDate: expirationDate)
                itemData = selectedFile != nil ? try Data(contentsOf: selectedFile!) : try JSONEncoder().encode(data)
                metadata["documentType"] = documentType
                metadata["expiration"] = expirationDate.ISO8601Format()
            case .photos:
                itemData = selectedPhotoData ?? Data()
                metadata["type"] = "photo"
            case .files:
                itemData = selectedFile != nil ? try Data(contentsOf: selectedFile!) : Data()
                metadata["filename"] = selectedFile?.lastPathComponent ?? "unknown"
            case .totp:
                let data = TOTPData(secret: totpSecret, issuer: totpIssuer, account: totpAccount)
                itemData = try JSONEncoder().encode(data)
                metadata["issuer"] = totpIssuer
                metadata["account"] = totpAccount
            }

            let newItem = VaultItem(
                category: category,
                title: title,
                note: note,
                payloadIdentifier: "", // Will be set by VaultManager
                metadata: metadata
            )

            try vaultManager.addItem(newItem, data: itemData)
            dismiss()
        } catch {
            print("Failed to save vault item: \(error)")
        }
    }
}
