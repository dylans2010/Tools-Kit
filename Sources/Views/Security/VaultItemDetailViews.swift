import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct AddVaultItemView: View {
    let type: VaultItemType
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vaultManager = VaultManager.shared

    @State private var title = ""
    @State private var username = ""
    @State private var password = ""
    @State private var url = ""
    @State private var notes = ""
    @State private var documentType = "ID"
    @State private var totpSecret = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedFileData: Data?
    @State private var selectedFileName = ""
    @State private var isSaving = false
    @State private var showFilePicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    TextField("Title", text: $title)
                }

                switch type {
                case .credential:
                    Section("Credentials") {
                        TextField("Username", text: $username)
                        SecureField("Password", text: $password)
                        TextField("Website URL", text: $url)
                    }
                case .document:
                    Section("Document Details") {
                        TextField("Document Type", text: $documentType)
                        Button("Select Document File") {
                            showFilePicker = true
                        }
                        if !selectedFileName.isEmpty {
                            Text(selectedFileName).foregroundColor(.green)
                        }
                    }
                case .totp:
                    Section("TOTP") {
                        TextField("Secret Key (Base32)", text: $totpSecret)
                        TextField("Issuer", text: $url)
                    }
                case .photo:
                    Section("Media") {
                        PhotosPicker("Select Photo", selection: $selectedPhotoItem, matching: .images)
                        if selectedPhotoItem != nil {
                            Text("Photo selected").foregroundColor(.green)
                        }
                    }
                case .file:
                    Section("File") {
                        Button("Select File") {
                            showFilePicker = true
                        }
                        if !selectedFileName.isEmpty {
                            Text(selectedFileName).foregroundColor(.green)
                        }
                    }
                }

                Section("Additional Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }

                Section {
                    Button(action: saveItem) {
                        if isSaving {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text("Save to Vault").bold().frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(title.isEmpty || isSaving)
                }
            }
            .navigationTitle("New \(type.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showFilePicker) {
                FileImporterView(allowedContentTypes: [.data, .pdf, .zip, .text]) { urls in
                    if let url = urls.first {
                        selectedFileName = url.lastPathComponent
                        selectedFileData = try? Data(contentsOf: url)
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedFileData = data
                        selectedFileName = "photo_\(Int(Date().timeIntervalSince1970)).jpg"
                    }
                }
            }
        }
    }

    private func saveItem() {
        isSaving = true
        Task { @MainActor in
            var item = VaultItem(type: type, title: title)
            var data: Data?

            switch type {
            case .credential:
                let meta = CredentialMetadata(username: username, url: url, notes: notes)
                item.credentialMetadata = meta
                data = password.data(using: .utf8)
            case .document:
                item.documentMetadata = DocumentMetadata(documentType: documentType, notes: notes)
                data = selectedFileData
                item.fileMetadata = FileMetadata(fileName: selectedFileName.isEmpty ? title : selectedFileName,
                                               fileSize: Int64(data?.count ?? 0),
                                               mimeType: "application/pdf")
            case .totp:
                item.totpMetadata = TOTPMetadata(issuer: url, accountName: username)
                data = totpSecret.data(using: .utf8)
            case .photo, .file:
                data = selectedFileData
                item.fileMetadata = FileMetadata(fileName: selectedFileName.isEmpty ? title : selectedFileName,
                                               fileSize: Int64(data?.count ?? 0),
                                               mimeType: "application/octet-stream")
            }

            do {
                try await vaultManager.addItem(item, data: data)
                dismiss()
            } catch {
                // Handle error
            }
            isSaving = false
        }
    }
}

struct VaultItemDetailView: View {
    let item: VaultItem
    @StateObject private var vaultManager = VaultManager.shared
    @State private var decryptedData: Data?
    @State private var isDecrypting = false
    @State private var showSecret = false
    @State private var totpCode = ""
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var showShareSheet = false

    var body: some View {
        mainList
            .navigationTitle(item.title)
            .sheet(isPresented: $showShareSheet) {
                #if os(iOS)
                if let data = decryptedData {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(item.fileMetadata?.fileName ?? "exported_file")
                    try? data.write(to: tempURL)
                    ShareSheet(items: [tempURL])
                }
                #else
                VStack {
                    Text("File decrypted and exported.")
                    Button("Close") { showShareSheet = false }
                }
                .padding()
                #endif
            }
            .onAppear {
                if item.type == .totp { decrypt() }
            }
    }

    private var mainList: some View {
        List {
            Section("Details") {
                detailRow(label: "Title", value: item.title)
                detailRow(label: "Created", value: item.createdAt.formatted())
            }

            switch item.type {
            case .credential:
                if let meta = item.credentialMetadata {
                    Section("Account") {
                        detailRow(label: "Username", value: meta.username)
                        if let url = meta.url { detailRow(label: "URL", value: url) }
                    }
                }
                Section("Secret") {
                    if showSecret, let data = decryptedData, let pass = String(data: data, encoding: .utf8) {
                        Text(pass).font(.system(.body, design: .monospaced))
                    } else {
                        Button("Reveal Password") { decrypt() }
                    }
                }

            case .totp:
                Section("One-Time Code") {
                    VStack(alignment: .center, spacing: 10) {
                        Text(totpCode.isEmpty ? "------" : totpCode)
                            .font(.system(size: 40, weight: .bold, design: .monospaced))

                        ProgressView(value: Double(Int(Date().timeIntervalSince1970) % 30), total: 30)
                            .tint(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                .onReceive(timer) { _ in updateTOTP() }

            case .photo:
                Section("Preview") {
                    if let data = decryptedData {
                        #if os(iOS)
                        if let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(8)
                        }
                        #elseif os(macOS)
                        if let nsImage = NSImage(data: data) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(8)
                        }
                        #endif
                    } else {
                        Button("Load Photo") { decrypt() }
                    }
                }

            case .document, .file:
                Section("File Info") {
                    if let meta = item.fileMetadata {
                        detailRow(label: "Filename", value: meta.fileName)
                        detailRow(label: "Size", value: ByteCountFormatter.string(fromByteCount: meta.fileSize, countStyle: .file))
                    }
                    Button("Decrypt & Export") {
                        decrypt()
                        if decryptedData != nil { showShareSheet = true }
                    }
                }
            }
        }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }

    private func decrypt() {
        isDecrypting = true
        Task {
            do {
                let data = try vaultManager.getItemData(item)
                await MainActor.run {
                    self.decryptedData = data
                    self.showSecret = true
                    if item.type == .totp { updateTOTP() }
                    if (item.type == .document || item.type == .file) && data != nil {
                        showShareSheet = true
                    }
                }
            } catch {
                // Handle error
            }
            await MainActor.run { isDecrypting = false }
        }
    }

    private func updateTOTP() {
        guard let data = decryptedData, let secret = String(data: data, encoding: .utf8) else { return }
        totpCode = TOTPService.shared.generateTOTP(secret: secret) ?? ""
    }
}
