import SwiftUI

struct SpreadsheetsHomeView: View {
    @StateObject private var manager = SpreadsheetsManager.shared
    @State private var showingCreate = false
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            Group {
                if manager.spreadsheets.isEmpty {
                    ContentUnavailableView {
                        Label("No Sheets Yet", systemImage: "tablecells")
                    } description: {
                        Text("Create a spreadsheet to get started with data analysis.")
                    } actions: {
                        Button("Create Spreadsheet") { showingCreate = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Computational Intelligence")
                                    .font(.title3.bold())
                                Text("Data analysis, forecasting, and formula automation at your fingertips.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }

                        Section("Your Sheets") {
                            ForEach(manager.spreadsheets) { sheet in
                                NavigationLink(destination: SpreadsheetEditorView(spreadsheet: sheet, manager: manager)) {
                                    Label {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(sheet.name)
                                                .font(.body.weight(.semibold))
                                            Text("\(sheet.rows) x \(sheet.columns)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    } icon: {
                                        Image(systemName: "tablecells")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Spreadsheets")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingCreate = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                createSheet
            }
        }
    }

    private var createSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $newName)
                } header: {
                    Text("Sheet Name")
                }
            }
            .navigationTitle("New Sheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingCreate = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let n = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                        manager.createSpreadsheet(name: n.isEmpty ? "Untitled" : n)
                        showingCreate = false
                    }
                    .bold()
                }
            }
        }
    }
}
