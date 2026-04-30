import SwiftUI

struct SpreadsheetsHomeView: View {
    @StateObject private var manager = SpreadsheetsManager.shared
    @State private var showingCreate = false
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.workspaceBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        heroHeader

                        if manager.spreadsheets.isEmpty {
                            emptyState
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                                ForEach(manager.spreadsheets) { sheet in
                                    NavigationLink(destination: SpreadsheetEditorView(spreadsheet: sheet, manager: manager)) {
                                        SpreadsheetThumbnail(sheet: sheet)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Spreadsheets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingCreate = true } label: { Image(systemName: "plus.circle.fill").font(.title3) }
                }
            }
            .sheet(isPresented: $showingCreate) {
                createSheet
            }
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Computational Intelligence")
                .font(.title2.bold())
            Text("Data analysis, forecasting, and formula automation at your fingertips.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 20))
        .padding()
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tablecells").font(.system(size: 44)).foregroundStyle(.secondary)
            Text("No Sheets Yet").font(.headline)
            Button("Create Spreadsheet") { showingCreate = true }.buttonStyle(.borderedProminent)
        }
        .padding(.top, 100)
    }

    private var createSheet: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $newName)
            }
            .navigationTitle("New Sheet")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        manager.createSpreadsheet(name: newName)
                        showingCreate = false
                    }
                }
            }
        }
    }
}

struct SpreadsheetThumbnail: View {
    let sheet: Spreadsheet
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.1))
                Image(systemName: "tablecells.fill").font(.title).foregroundStyle(.green)
            }
            .frame(height: 100)

            Text(sheet.name).font(.caption.bold()).lineLimit(1).foregroundStyle(.white)
            Text("\(sheet.rows)x\(sheet.columns)").font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .padding(8)
        .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 16))
    }
}
