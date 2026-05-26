import SwiftUI

struct DiagnosticReportItem: Identifiable, Codable {
    let id: UUID
    let toolName: String
    let category: String
    let status: DiagnosticReportStatus
    let details: String
    let timestamp: Date
    var grade: String? // A, B, C, D, F for Repair Shop Mode
    var technicianNote: String?

    init(toolName: String, category: String, status: DiagnosticReportStatus, details: String, grade: String? = nil, technicianNote: String? = nil) {
        self.id = UUID()
        self.toolName = toolName
        self.category = category
        self.status = status
        self.details = details
        self.timestamp = Date()
        self.grade = grade
        self.technicianNote = technicianNote
    }
}

enum DiagnosticReportStatus: String, Codable, CaseIterable {
    case passed = "Passed"
    case failed = "Failed"
    case warning = "Warning"
    case info = "Info"

    var icon: String {
        switch self {
        case .passed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .passed: return .green
        case .failed: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

struct DiagnosticReport: Identifiable, Codable {
    let id: UUID
    let title: String
    let createdAt: Date
    var items: [DiagnosticReportItem]
    let deviceModel: String
    let osVersion: String

    // Repair Shop Metadata
    var technicianName: String?
    var customerName: String?
    var shopName: String?
    var deviceSerial: String?

    init(title: String, items: [DiagnosticReportItem], technicianName: String? = nil, customerName: String? = nil, shopName: String? = nil, deviceSerial: String? = nil) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.items = items
        self.deviceModel = UIDevice.current.model
        self.osVersion = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        self.technicianName = technicianName
        self.customerName = customerName
        self.shopName = shopName
        self.deviceSerial = deviceSerial
    }

    var passedCount: Int { items.filter { $0.status == .passed }.count }
    var failedCount: Int { items.filter { $0.status == .failed }.count }
    var warningCount: Int { items.filter { $0.status == .warning }.count }
    var infoCount: Int { items.filter { $0.status == .info }.count }
}

final class DiagnosticReportManager: ObservableObject {
    static let shared = DiagnosticReportManager()

    @Published var reports: [DiagnosticReport] = []
    @Published var currentItems: [DiagnosticReportItem] = []
    @Published var isAutoLoggingEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isAutoLoggingEnabled, forKey: autoLoggingKey)
        }
    }

    private let storageKey = "diagnosticReports"
    private let autoLoggingKey = "diagnosticAutoLogging"

    private init() {
        isAutoLoggingEnabled = UserDefaults.standard.bool(forKey: autoLoggingKey)
        loadReports()
    }

    func logIfEnabled(toolName: String, category: String, status: DiagnosticReportStatus, details: String) {
        guard isAutoLoggingEnabled else { return }
        addItem(toolName: toolName, category: category, status: status, details: details)
    }

    func addItem(toolName: String, category: String, status: DiagnosticReportStatus, details: String) {
        let item = DiagnosticReportItem(toolName: toolName, category: category, status: status, details: details)
        DispatchQueue.main.async {
            self.currentItems.append(item)
        }
    }

    func saveReport(title: String) {
        let report = DiagnosticReport(title: title, items: currentItems)
        reports.insert(report, at: 0)
        currentItems = []
        persistReports()
    }

    func deleteReport(at offsets: IndexSet) {
        reports.remove(atOffsets: offsets)
        persistReports()
    }

    func deleteReport(id: UUID) {
        reports.removeAll { $0.id == id }
        persistReports()
    }

    func clearCurrentItems() {
        currentItems = []
    }

    func exportReportAsText(_ report: DiagnosticReport) -> String {
        var text = "DIAGNOSTIC REPORT\n"
        text += "=================\n"
        if let shop = report.shopName { text += "Shop: \(shop)\n" }
        text += "Title: \(report.title)\n"
        text += "Date: \(formattedDate(report.createdAt))\n"
        if let tech = report.technicianName { text += "Technician: \(tech)\n" }
        if let cust = report.customerName { text += "Customer: \(cust)\n" }
        text += "Device: \(report.deviceModel)\n"
        if let serial = report.deviceSerial { text += "Serial: \(serial)\n" }
        text += "OS: \(report.osVersion)\n\n"
        text += "SUMMARY\n"
        text += "-------\n"
        text += "Passed: \(report.passedCount)\n"
        text += "Failed: \(report.failedCount)\n"
        text += "Warnings: \(report.warningCount)\n"
        text += "Info: \(report.infoCount)\n"
        text += "Total: \(report.items.count)\n\n"
        text += "DETAILS\n"
        text += "-------\n"
        for item in report.items {
            var statusStr = item.status.rawValue.uppercased()
            if let grade = item.grade { statusStr += " | GRADE: \(grade)" }
            text += "[\(statusStr)] \(item.toolName) (\(item.category))\n"
            text += "  \(item.details)\n"
            if let note = item.technicianNote { text += "  Note: \(note)\n" }
            text += "  Time: \(formattedDate(item.timestamp))\n\n"
        }
        return text
    }

    func exportReportAsCSV(_ report: DiagnosticReport) -> String {
        var csv = "Status,Tool,Category,Details,Timestamp\n"
        for item in report.items {
            let details = item.details.replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\"\(item.status.rawValue)\",\"\(item.toolName)\",\"\(item.category)\",\"\(details)\",\"\(formattedDate(item.timestamp))\"\n"
        }
        return csv
    }

    func exportReportAsJSON(_ report: DiagnosticReport) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(report) {
            return String(data: data, encoding: .utf8) ?? "{}"
        }
        return "{}"
    }

    private func persistReports() {
        if let data = try? JSONEncoder().encode(reports) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadReports() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([DiagnosticReport].self, from: data) {
            reports = decoded
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
