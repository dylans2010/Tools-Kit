import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vaultManager = VaultManager.shared

    @State private var category: VaultCategory = .credentials
    @State private var title = ""
    @State private var note = ""

    // Credential state
    @State private var username = ""
    @State private var password = ""
    @State private var website = ""

    // Document state
    @State private var docType = "ID"
    @State private var expirationDate = Date()

    // TOTP state
    @State private var totpSecret = ""
    @State private var totpIssuer = ""

    // Media state
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedFileData: Data?
    @State private var selectedFileName: String?

    @State private var showingFilePicker = false
    @State private var showingFileImporterBridge = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("General")) {
                    Picker("Category", selection: $category) {
                        ForEach(VaultCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                    TextField("Title", text: $title)
                    TextField("Notes", text: $note, axis: .vertical)
                }

                categorySpecificSection

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("New Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveItem() }
                        .disabled(title.isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private var categorySpecificSection: some View {
        switch category {
        case .credentials:
            Section(header: Text("Credential Details")) {
                TextField("Username", text: $username)
                SecureField("Password", text: $password)
                TextField("Website", text: $website)
            }
        case .documents:
            Section(header: Text("Document Details")) {
                TextField("Document Type", text: $docType)
                DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
            }
        case .totp:
            Section(header: Text("TOTP Details")) {
                TextField("Issuer", text: $totpIssuer)
                TextField("Secret (Base32)", text: $totpSecret)
                    .textInputAutocapitalization(.characters)
            }
        case .photos:
            Section(header: Text("Import Photo")) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                }
            }
        case .files:
            Section(header: Text("Import File")) {
                Button {
                    showingFilePicker = true
                } label: {
                    Label(selectedFileName ?? "Choose File", systemImage: "doc.badge.plus")
                }

                Button {
                    showingFileImporterBridge = true
                } label: {
                    Label("Import via Document Picker", systemImage: "square.and.arrow.down")
                }
            }
            .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.item], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    if url.startAccessingSecurityScopedResource() {
                        defer { url.stopAccessingSecurityScopedResource() }
                        self.selectedFileName = url.lastPathComponent
                        self.selectedFileData = try? Data(contentsOf: url)
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
            .sheet(isPresented: $showingFileImporterBridge) {
                FileImporterRepresentableView(allowedContentTypes: [.item], allowsMultipleSelection: false) { urls in
                    guard let url = urls.first else { return }
                    if url.startAccessingSecurityScopedResource() {
                        defer { url.stopAccessingSecurityScopedResource() }
                        self.selectedFileName = url.lastPathComponent
                        self.selectedFileData = try? Data(contentsOf: url)
                    } else {
                        self.errorMessage = "Unable to access selected file."
                    }
                }
            }
        }
    }

    private func saveItem() {
        Task {
            do {
                var data: Data = Data()

                switch category {
                case .credentials:
                    let cred = CredentialData(username: username, password: password, website: website)
                    data = try JSONEncoder().encode(cred)
                case .documents:
                    let doc = DocumentData(documentType: docType, expirationDate: expirationDate)
                    data = try JSONEncoder().encode(doc)
                case .totp:
                    let totp = TOTPData(secret: totpSecret, issuer: totpIssuer, account: username)
                    data = try JSONEncoder().encode(totp)
                case .photos:
                    if let imageItem = selectedPhoto,
                       let imageData = try? await imageItem.loadTransferable(type: Data.self) {
                        data = imageData
                    } else {
                        errorMessage = "No photo selected"
                        return
                    }
                case .files:
                    // In a real impl, we'd handle the UIDocumentPicker results
                    if let fileData = selectedFileData {
                        data = fileData
                    } else {
                        errorMessage = "No file selected"
                        return
                    }
                }

                let item = VaultItem(category: category, title: title, note: note, payloadIdentifier: "")
                try vaultManager.addItem(item, data: data)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct EditItemView: View {
    let item: VaultItem
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vaultManager = VaultManager.shared

    @State private var title: String
    @State private var note: String

    init(item: VaultItem) {
        self.item = item
        _title = State(initialValue: item.title)
        _note = State(initialValue: item.note)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Edit Info")) {
                    TextField("Title", text: $title)
                    TextField("Notes", text: $note, axis: .vertical)
                }
            }
            .navigationTitle("Edit Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update") {
                        var updated = item
                        updated.title = title
                        updated.note = note
                        try? vaultManager.updateItem(updated)
                        dismiss()
                    }
                }
            }
        }
    }
}
