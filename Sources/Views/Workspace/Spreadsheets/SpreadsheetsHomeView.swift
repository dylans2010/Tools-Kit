import SwiftUI

struct SpreadsheetsHomeView: View {
    @StateObject private var manager = SpreadsheetsManager.shared
    @State private var showingCreate = false
    @State private var newName = ""
    @State private var sheetToDelete: Spreadsheet?
    @State private var showDeleteConfirm = false
    private let columns = [GridItem(.adaptive(minimum: 200), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                Section {
                    VStack(spacing: 16) {
                        if manager.spreadsheets.isEmpty {
                            EmptyStateView(
                                icon: "tablecells",
                                title: "No Spreadsheets",
                                message: "Create a spreadsheet or import data to begin analysis.",
                                action: { showingCreate = true },
                                actionLabel: "Create Spreadsheet"
                            )
                        } else {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(manager.spreadsheets) { sheet in
                                    NavigationLink {
                                        SpreadsheetEditorView(spreadsheet: sheet, manager: manager)
                                    } label: {
                                        SpreadsheetCard(sheet: sheet) {
                                            sheetToDelete = sheet
                                            showDeleteConfirm = true
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(16)
                } header: {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Spreadsheets")
                                .font(.title3.weight(.semibold))
                            Spacer()
                            Button { showingCreate = true } label: {
                                Label("New Sheet", systemImage: "plus")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        Text("Build structured datasets with AI-powered formulas and insights.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial)
                    .overlay(Divider(), alignment: .bottom)
                }
            }
        }
        .navigationTitle("Spreadsheets")
        .sheet(isPresented: $showingCreate) {
            NavigationStack {
                Form {
                    Section("Name") {
                        TextField("Spreadsheet Name", text: $newName)
                    }
                }
                .navigationTitle("New Spreadsheet")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            newName = ""
                            showingCreate = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") {
                            let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                            manager.createSpreadsheet(name: name.isEmpty ? "Untitled Spreadsheet" : name)
                            newName = ""
                            showingCreate = false
                        }
                    }
                }
            }
        }
        .confirmationDialog("Delete \"\(sheetToDelete?.name ?? "")\"?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let sheetToDelete { manager.deleteSpreadsheet(sheetToDelete) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

private struct SpreadsheetCard: View {
    let sheet: Spreadsheet
    let onDelete: () -> Void

    var body: some View {
        WorkspaceSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.green.opacity(0.12))
                    .frame(height: 90)
                    .overlay(
                        Image(systemName: "tablecells.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                    )
                Text(sheet.name)
                    .font(.headline)
                    .lineLimit(1)
                HStack {
                    WorkspaceStatusBadge(title: "\(sheet.rows)×\(sheet.columns)", color: .green)
                    Spacer()
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
