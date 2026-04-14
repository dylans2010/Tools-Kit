import SwiftUI

struct SpreadsheetsHomeView: View {
    @StateObject private var manager = SpreadsheetsManager.shared
    @State private var showingCreate = false
    @State private var newName = ""
    @State private var sheetToDelete: Spreadsheet? = nil
    @State private var showDeleteConfirm = false

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 10) {
                    actionButton("New Spreadsheet", icon: "plus.rectangle.on.rectangle", color: .green) {
                        showingCreate = true
                    }
                }
                .padding(.horizontal)

                if manager.spreadsheets.isEmpty {
                    EmptyStateView(
                        icon: "tablecells",
                        title: "No Spreadsheets",
                        message: "Create your first spreadsheet to get started.",
                        action: { showingCreate = true },
                        actionLabel: "Create Spreadsheet"
                    )
                } else {
                    Text("Your Spreadsheets")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 14) {
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
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Spreadsheets")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingCreate = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            createSheet
        }
        .confirmationDialog("Delete \"\(sheetToDelete?.name ?? "")\"?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let s = sheetToDelete { manager.deleteSpreadsheet(s) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var createSheet: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Spreadsheet Name", text: $newName)
                }
            }
            .navigationTitle("New Spreadsheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { newName = ""; showingCreate = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        let n = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                        manager.createSpreadsheet(name: n.isEmpty ? "Untitled Spreadsheet" : n)
                        newName = ""
                        showingCreate = false
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func actionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title3)
                Text(title).font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}

private struct SpreadsheetCard: View {
    let sheet: Spreadsheet
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Mini grid preview
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.12))
                .frame(height: 80)
                .overlay(
                    Image(systemName: "tablecells")
                        .font(.title2)
                        .foregroundColor(.green.opacity(0.5))
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(sheet.name)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    Spacer()
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                Text("\(sheet.rows)×\(sheet.columns)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(sheet.updatedAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}
