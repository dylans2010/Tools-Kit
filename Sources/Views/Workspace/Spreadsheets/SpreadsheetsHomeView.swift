import SwiftUI

struct SpreadsheetsHomeView: View {
    @StateObject private var manager = SpreadsheetsManager.shared
    @State private var showingCreate = false
    @State private var newName = ""
    @State private var sheetToDelete: Spreadsheet?
    @State private var showDeleteConfirm = false
    @State private var aiPrompt = ""
    @State private var aiLoading = false
    @State private var aiError: String?
    @State private var aiResult: SpreadsheetsManager.SpreadsheetAIPayload?
    private let columns = [GridItem(.adaptive(minimum: 200), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                featureHero
                aiPlannerCard

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

    private var featureHero: some View {
        WorkspaceSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spreadsheets")
                            .font(.title2.bold())
                        Text("Build clear datasets with formula intelligence and instant AI insights.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        showingCreate = true
                    } label: {
                        Label("New Sheet", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                HStack(spacing: 8) {
                    aiAction("Forecast", icon: "chart.line.uptrend.xyaxis") {
                        runAI("Forecast trends from this business table.")
                    }
                    aiAction("Audit", icon: "checkmark.shield") {
                        runAI("Audit this sheet for data quality issues and anomalies.")
                    }
                    aiAction("Formulas", icon: "function") {
                        runAI("Suggest formulas for KPIs, totals, and ratios.")
                    }
                }
            }
        }
    }

    private var aiPlannerCard: some View {
        WorkspaceSurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("AI Spreadsheet Copilot")
                    .font(.headline)
                TextField("Ask for formulas, chart plans, or data cleanup strategy…", text: $aiPrompt)
                    .textFieldStyle(.roundedBorder)
                if aiLoading {
                    WorkspaceSkeletonLine()
                    WorkspaceSkeletonLine(widthRatio: 0.7)
                } else if let aiError {
                    Text(aiError)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if let aiResult {
                    Text(aiResult.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    insightRow("Formulas", aiResult.formulaSuggestions)
                    insightRow("Charts", aiResult.chartSuggestions)
                }
                Button("Analyze Request") { runAI() }
                    .buttonStyle(.borderedProminent)
                    .disabled(aiLoading || aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func insightRow(_ title: String, _ values: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
            ForEach(values.prefix(3), id: \.self) { value in
                Text("• \(value)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func aiAction(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
        }
        .buttonStyle(.bordered)
    }

    private func runAI(_ preset: String? = nil) {
        let prompt = (preset ?? aiPrompt).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        aiLoading = true
        aiError = nil
        Task {
            do {
                let preview = manager.spreadsheets.first.map { sheet in
                    "Sheet \(sheet.name), \(sheet.rows)x\(sheet.columns)"
                } ?? "No current spreadsheet data. Suggest setup guidance."
                let result = try await manager.analyzeSpreadsheet(prompt: prompt, dataPreview: preview)
                await MainActor.run {
                    aiResult = result
                    if preset != nil { aiPrompt = prompt }
                    aiLoading = false
                }
            } catch {
                await MainActor.run {
                    aiError = "Could not generate spreadsheet guidance. Try a more specific ask."
                    aiLoading = false
                }
            }
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
