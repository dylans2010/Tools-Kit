import SwiftUI

struct VaultListView: View {
    let category: VaultCategory
    @StateObject private var vaultManager = VaultManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(vaultManager.items(for: category)) { item in
                NavigationLink(destination: VaultItemDetailView(item: item)) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.title)
                                .font(.headline)
                            if !item.note.isEmpty {
                                Text(item.note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
            .onDelete(perform: deleteItems)
        }
        .navigationTitle(category.rawValue)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .overlay {
            if vaultManager.items(for: category).isEmpty {
                ContentUnavailableView("No \(category.rawValue)", systemImage: category.icon, description: Text("Securely store your sensitive \(category.rawValue.lowercased()) here."))
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { vaultManager.items(for: category)[$0] }
        for item in itemsToDelete {
            vaultManager.deleteItem(item)
        }
    }
}

struct VaultItemDetailView: View {
    @State var item: VaultItem
    @StateObject private var vaultManager = VaultManager.shared
    @State private var decryptedData: Data?
    @State private var errorMessage: String?
    @State private var showingEditSheet = false

    var body: some View {
        List {
            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section {
                LabeledContent("Title", value: item.title)
                if !item.note.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Note")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(item.note)
                    }
                }
                LabeledContent("Created", value: item.createdAt.formatted())
                LabeledContent("Updated", value: item.updatedAt.formatted())
            } header: {
                Text("Details")
            }

            contentSection
        }
        .navigationTitle(item.title)
        .toolbar {
            Button("Edit") { showingEditSheet = true }
        }
        .onAppear {
            loadData()
        }
        .sheet(isPresented: $showingEditSheet) {
            EditItemView(item: item)
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        switch item.category {
        case .credentials:
            if let data = decryptedData, let creds = try? JSONDecoder().decode(CredentialData.self, from: data) {
                CredentialInfoSection(creds: creds)
            }
        case .documents:
            if let data = decryptedData,
               let doc = try? JSONDecoder().decode(DocumentData.self, from: data) {
                DocumentInfoSection(doc: doc)
            }
        case .photos:
            Section {
                if let data = decryptedData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(8)
                } else {
                    ProgressView()
                }
            } header: {
                Text("Photo")
            }
        case .files:
            Section {
                LabeledContent("Filename", value: item.payloadIdentifier)
                if let data = decryptedData {
                    ShareLink(item: data, preview: SharePreview(item.title, image: Image(systemName: "doc.fill"))) {
                        Label("Share Decrypted File", systemImage: "square.and.arrow.up")
                    }
                }
            } header: {
                Text("File")
            }
        case .totp:
            if let data = decryptedData, let totp = try? JSONDecoder().decode(TOTPData.self, from: data) {
                TOTPDetailSection(data: totp)
            }
        }
    }

    private func loadData() {
        Task {
            do {
                decryptedData = try await vaultManager.loadItemData(item)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct SecureLabeledContent: View {
    let label: String
    let value: String
    @State private var isVisible = false

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            if isVisible {
                Text(value)
                    .font(.body.monospaced())
            } else {
                Text("••••••••")
            }
            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
            }
            .buttonStyle(.borderless)
        }
    }
}

struct TOTPDetailSection: View {
    let data: TOTPData
    @State private var currentCode = ""
    @State private var timeRemaining = 0
    @State private var showCopyConfirmation = false

    var body: some View {
        Section {
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                VStack(alignment: .center, spacing: 12) {
                    Text(currentCode)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(.blue)
                        .contentTransition(.numericText())

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 8)

                        Capsule()
                            .fill(timeRemaining < 5 ? Color.red : Color.blue)
                            .frame(width: max(0, CGFloat(timeRemaining) / CGFloat(data.period) * 300), height: 8)
                            .animation(.linear(duration: 1), value: timeRemaining)
                    }
                    .frame(width: 300)

                    HStack {
                        Text("\(timeRemaining)s")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            UIPasteboard.general.string = currentCode
                            withAnimation { showCopyConfirmation = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showCopyConfirmation = false }
                            }
                        } label: {
                            Label(showCopyConfirmation ? "Copied" : "Copy", systemImage: showCopyConfirmation ? "checkmark" : "doc.on.doc")
                                .font(.caption.bold())
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(showCopyConfirmation ? .green : .blue)
                    }
                    .frame(width: 300)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .onChange(of: timeline.date) { _, _ in
                    updateCode()
                }
            }
        } header: {
            Text("One-Time Code")
        }
        .onAppear(perform: updateCode)
    }

    private func updateCode() {
        currentCode = TOTPService.shared.generateTOTP(secret: data.secret, digits: data.digits, period: data.period) ?? "ERROR"
        timeRemaining = TOTPService.shared.timeRemaining(period: data.period)
    }
}

struct CredentialInfoSection: View {
    let creds: CredentialData

    var body: some View {
        Section {
            LabeledContent("Username", value: creds.username)
            SecureLabeledContent(label: "Password", value: creds.password)
            if !creds.website.isEmpty {
                LabeledContent("Website", value: creds.website)
            }
        } header: {
            Text("Credential")
        }
    }
}

struct DocumentInfoSection: View {
    let doc: DocumentData

    var body: some View {
        Section {
            LabeledContent("Type", value: doc.documentType)
            if let expiry = doc.expirationDate {
                LabeledContent("Expires", value: expiry.formatted(date: .abbreviated, time: .omitted))
            }
            Text("No preview available for this document type")
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Document Info")
        }
    }
}
