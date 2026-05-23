import SwiftUI

struct DiagnosticReportsView: View {
    @StateObject private var reportManager = DiagnosticReportManager.shared
    @State private var showingSaveSheet = false
    @State private var reportTitle = ""
    @State private var selectedReport: DiagnosticReport?
    @State private var showingExportSheet = false
    @State private var filterStatus: DiagnosticReportStatus?

    var body: some View {
        List {
            Section("Auto-Logging") {
                Toggle(isOn: $reportManager.isAutoLoggingEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto-Log Diagnostics")
                            .font(.subheadline.weight(.medium))
                        Text(reportManager.isAutoLoggingEnabled
                            ? "All diagnostic results will be logged automatically"
                            : "Enable to capture all diagnostic data into reports")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.blue)

                if reportManager.isAutoLoggingEnabled {
                    HStack {
                        Image(systemName: "record.circle")
                            .foregroundStyle(.red)
                            .symbolEffect(.pulse, isActive: true)
                        Text("Recording all diagnostic results...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !reportManager.currentItems.isEmpty {
                Section("Current Session (\(reportManager.currentItems.count) items)") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(reportManager.currentItems.count) items recorded")
                                .font(.subheadline.weight(.medium))
                            Text("Tap Save to create a report")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Save") { showingSaveSheet = true }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }

                    HStack(spacing: 12) {
                        let passed = reportManager.currentItems.filter { $0.status == .passed }.count
                        let failed = reportManager.currentItems.filter { $0.status == .failed }.count
                        let warnings = reportManager.currentItems.filter { $0.status == .warning }.count
                        let info = reportManager.currentItems.filter { $0.status == .info }.count
                        Label("\(passed)", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                        Label("\(failed)", systemImage: "xmark.circle.fill").foregroundStyle(.red)
                        Label("\(warnings)", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        Label("\(info)", systemImage: "info.circle.fill").foregroundStyle(.blue)
                    }
                    .font(.caption2)

                    if filterStatus != nil {
                        Button("Clear Filter") { filterStatus = nil }
                            .font(.caption)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(DiagnosticReportStatus.allCases, id: \.self) { status in
                                Button {
                                    filterStatus = filterStatus == status ? nil : status
                                } label: {
                                    Text(status.rawValue)
                                        .font(.caption2.weight(.medium))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(filterStatus == status ? status.color.opacity(0.3) : Color(.tertiarySystemFill))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    ForEach(filteredCurrentItems) { item in
                        reportItemRow(item)
                    }
                }
            }

            Section("Saved Reports") {
                if reportManager.reports.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text("No saved reports")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Enable auto-logging and run diagnostics to create reports")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    ForEach(reportManager.reports) { report in
                        NavigationLink {
                            DiagnosticReportDetailView(report: report)
                        } label: {
                            reportRow(report)
                        }
                    }
                    .onDelete(perform: reportManager.deleteReport)
                }
            }
        }
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !reportManager.currentItems.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") { reportManager.clearCurrentItems() }
                        .font(.caption)
                }
            }
        }
        .sheet(isPresented: $showingSaveSheet) {
            saveReportSheet
        }
    }

    private var filteredCurrentItems: [DiagnosticReportItem] {
        if let status = filterStatus {
            return reportManager.currentItems.filter { $0.status == status }
        }
        return reportManager.currentItems
    }

    private func reportItemRow(_ item: DiagnosticReportItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.status.icon)
                .foregroundStyle(item.status.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.toolName)
                    .font(.subheadline.weight(.medium))
                Text(item.details)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Text(item.timestamp, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func reportRow(_ report: DiagnosticReport) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(report.title)
                .font(.subheadline.weight(.medium))
            HStack(spacing: 12) {
                Label("\(report.passedCount)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Label("\(report.failedCount)", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Label("\(report.warningCount)", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Label("\(report.infoCount)", systemImage: "info.circle.fill")
                    .foregroundStyle(.blue)
            }
            .font(.caption2)
            Text(formattedDate(report.createdAt))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private var saveReportSheet: some View {
        NavigationStack {
            Form {
                Section("Report Title") {
                    TextField("Enter a title", text: $reportTitle)
                }
                Section("Summary") {
                    let passed = reportManager.currentItems.filter { $0.status == .passed }.count
                    let failed = reportManager.currentItems.filter { $0.status == .failed }.count
                    let warnings = reportManager.currentItems.filter { $0.status == .warning }.count
                    let info = reportManager.currentItems.filter { $0.status == .info }.count
                    LabeledContent("Total Items") { Text("\(reportManager.currentItems.count)") }
                    LabeledContent("Passed") { Text("\(passed)").foregroundStyle(.green) }
                    LabeledContent("Failed") { Text("\(failed)").foregroundStyle(.red) }
                    LabeledContent("Warnings") { Text("\(warnings)").foregroundStyle(.orange) }
                    LabeledContent("Info") { Text("\(info)").foregroundStyle(.blue) }
                }

                Section("Categories Covered") {
                    let categories = Set(reportManager.currentItems.map { $0.category })
                    ForEach(Array(categories).sorted(), id: \.self) { cat in
                        let count = reportManager.currentItems.filter { $0.category == cat }.count
                        LabeledContent(cat) { Text("\(count) items").font(.caption) }
                    }
                }
            }
            .navigationTitle("Save Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingSaveSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let title = reportTitle.isEmpty ? "Report \(formattedDate(Date()))" : reportTitle
                        reportManager.saveReport(title: title)
                        reportTitle = ""
                        showingSaveSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DiagnosticReportDetailView: View {
    let report: DiagnosticReport
    @State private var showingShareSheet = false
    @State private var exportFormat: ExportFormat = .text
    @StateObject private var reportManager = DiagnosticReportManager.shared

    enum ExportFormat: String, CaseIterable {
        case text = "Text"
        case csv = "CSV"
        case json = "JSON"
    }

    var body: some View {
        List {
            Section("Summary") {
                HStack(spacing: 16) {
                    statBadge(count: report.passedCount, label: "Passed", color: .green)
                    statBadge(count: report.failedCount, label: "Failed", color: .red)
                    statBadge(count: report.warningCount, label: "Warnings", color: .orange)
                    statBadge(count: report.infoCount, label: "Info", color: .blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Device") {
                LabeledContent("Model") { Text(report.deviceModel) }
                LabeledContent("OS") { Text(report.osVersion) }
                LabeledContent("Date") { Text(formattedDate(report.createdAt)) }
                LabeledContent("Total Items") { Text("\(report.items.count)") }
            }

            Section("Export") {
                Picker("Format", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)

                ShareLink(item: exportContent) {
                    Label("Export Report (\(exportFormat.rawValue))", systemImage: "square.and.arrow.up")
                }
            }

            Section("Results (\(report.items.count))") {
                ForEach(report.items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: item.status.icon)
                                .foregroundStyle(item.status.color)
                            Text(item.toolName)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(item.category)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(Capsule())
                        }
                        Text(item.details)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(reportManager.formattedDate(item.timestamp))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(report.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var exportContent: String {
        switch exportFormat {
        case .text: return reportManager.exportReportAsText(report)
        case .csv: return reportManager.exportReportAsCSV(report)
        case .json: return reportManager.exportReportAsJSON(report)
        }
    }

    private func statBadge(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
