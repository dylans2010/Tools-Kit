/*
 REDESIGN SUMMARY:
 - Standardized on native Form architecture with a segmented tab selector.
 - Modernized Endpoint Selection using a native Picker with monospaced method badges.
 - Standardized Request Body and Headers management using monospaced typography and native row editing.
 - Modernized the Response Console with semantic status badges, response timers, and dark monospaced output area.
 - strictly preserved all ConnectorExecutionService integration, request history, and cURL generation logic.
 - Improved visual hierarchy for history entries using semantic color coding and progress indicators.
 - Extracted sub-structs for RequestBodySection, HeadersSection, and ResponseConsoleSection to meet line-count limits.
 - Modernized sheets (cURL Export) with appropriate detents and copy actions.
 */

import SwiftUI

struct ConnectorTestConsoleView: View {
    @State var connector: ConnectorDefinition
    @Environment(\.dismiss) var dismiss

    @State private var selectedEndpointID: UUID?
    @State private var requestBody = "{}"
    @State private var responseOutput = "No Data"
    @State private var isExecuting = false
    @State private var statusCode: Int?
    @State private var responseTime: TimeInterval?
    @State private var requestHistory: [TestRequest] = []
    @State private var selectedTab = 0
    @State private var customHeaders: [HeaderEntry] = []
    @State private var showingCurlExport = false
    @State private var curlCommand = ""
    @State private var responseContentType = ""

    struct TestRequest: Identifiable { let id = UUID(); let endpoint: String; let method: String; let statusCode: Int?; let responseTime: TimeInterval?; let timestamp: Date; let response: String }
    struct HeaderEntry: Identifiable { let id = UUID(); var key: String; var value: String }

    var selectedEndpoint: ConnectorEndpoint? { guard let id = selectedEndpointID else { return nil }; return connector.endpoints.first(where: { $0.id == id }) }

    var body: some View {
        List {
            Section("API Simulation") {
                Picker("Target Endpoint", selection: $selectedEndpointID) {
                    Text("Select...").tag(Optional<UUID>.none)
                    ForEach(connector.endpoints) { ep in
                        HStack { Text(ep.method).font(.system(size: 9, weight: .black, design: .monospaced)); Text(ep.path).font(.caption2.monospaced()) }.tag(Optional(ep.id))
                    }
                }
                if let ep = selectedEndpoint {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack { Text(ep.method).font(.system(size: 10, weight: .black, design: .monospaced)).padding(.horizontal, 6).padding(.vertical, 2).background(methodColor(ep.method).opacity(0.1), in: Capsule()).foregroundStyle(methodColor(ep.method)); Text(ep.path).font(.caption2.monospaced()).lineLimit(1).foregroundStyle(.secondary) }
                        if !ep.headers.isEmpty { Text("\(ep.headers.count) default headers").font(.system(size: 8)).foregroundStyle(.tertiary) }
                    }.padding(.vertical, 4)
                }
            }

            Picker("Configuration", selection: $selectedTab) { Text("Body").tag(0); Text("Headers").tag(1); Text("History").tag(2) }.pickerStyle(.segmented).listRowBackground(Color.clear)

            switch selectedTab {
            case 0: RequestBodySection(bodyText: $requestBody, onFormat: formatRequestBody)
            case 1: HeadersSection(headers: $customHeaders)
            case 2: TestHistorySection(history: requestHistory) { responseOutput = $0.response; statusCode = $0.statusCode; responseTime = $0.responseTime }
            default: EmptyView()
            }

            Section {
                Button(action: runTest) {
                    HStack {
                        Spacer()
                        if isExecuting { ProgressView().padding(.trailing, 4); Text("Sending...") } else { Label("Send Request", systemImage: "paperplane.fill") }
                        Spacer()
                    }.frame(maxWidth: .infinity).bold()
                }.buttonStyle(.borderedProminent).disabled(isExecuting || selectedEndpointID == nil)
            }.listRowBackground(Color.clear)

            Section("Response Console") {
                ResponseMetricsHeader(code: statusCode, time: responseTime, type: responseContentType)
                ScrollView { Text(responseOutput).font(.system(size: 9, design: .monospaced)).padding(8).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled) }
                    .frame(minHeight: 200).background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))

                if statusCode != nil {
                    HStack {
                        Button(action: { UIPasteboard.general.string = responseOutput }) { Label("Copy", systemImage: "doc.on.doc").font(.caption2) }.buttonStyle(.bordered)
                        Button(action: { generateCurlCommand(); showingCurlExport = true }) { Label("cURL", systemImage: "terminal").font(.caption2) }.buttonStyle(.bordered)
                        Spacer(); Button(action: clearResponse) { Label("Clear", systemImage: "trash").font(.caption2) }.buttonStyle(.bordered).tint(.red)
                    }
                }
            }
        }
        .listStyle(.insetGrouped).navigationTitle("Test Console").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        .sheet(isPresented: $showingCurlExport) { CurlExportSheet(cmd: curlCommand).presentationDetents([.medium]) }
    }

    private func methodColor(_ m: String) -> Color { switch m.uppercased() { case "GET": return .blue; case "POST": return .green; case "PUT": return .orange; case "DELETE": return .red; default: return .secondary } }
    private func formatRequestBody() { guard let data = requestBody.data(using: .utf8), let json = try? JSONSerialization.jsonObject(with: data), let formatted = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]), let res = String(data: formatted, encoding: .utf8) else { return }; requestBody = res }
    private func clearResponse() { responseOutput = "No Data"; statusCode = nil; responseTime = nil; responseContentType = "" }
    private func generateCurlCommand() { guard let ep = selectedEndpoint else { return }; var cmd = "curl -X \(ep.method) '\(ep.path)'"; customHeaders.forEach { if !$0.key.isEmpty { cmd += " -H '\($0.key): \($0.value)'" } }; ep.headers.forEach { cmd += " -H '\($0.key): \($0.value)'" }; if ep.method != "GET" && !requestBody.isEmpty { cmd += " -d '\(requestBody)'" }; curlCommand = cmd }
    private func runTest() {
        guard let eid = selectedEndpointID, let ep = connector.endpoints.first(where: { $0.id == eid }) else { return }
        isExecuting = true; responseOutput = "Sending..."; let start = Date()
        Task {
            do {
                let data = try await ConnectorExecutionService.shared.execute(endpoint: ep, connector: connector)
                let elapsed = Date().timeIntervalSince(start); let out = String(data: data, encoding: .utf8) ?? "Invalid Data"
                await MainActor.run { responseOutput = out; statusCode = 200; responseTime = elapsed; responseContentType = "application/json"; isExecuting = false; requestHistory.insert(.init(endpoint: ep.path, method: ep.method, statusCode: 200, responseTime: elapsed, timestamp: Date(), response: out), at: 0) }
            } catch {
                let elapsed = Date().timeIntervalSince(start)
                await MainActor.run { responseOutput = "Error: \(error.localizedDescription)"; statusCode = (error as NSError).code; responseTime = elapsed; isExecuting = false; requestHistory.insert(.init(endpoint: ep.path, method: ep.method, statusCode: (error as NSError).code, responseTime: elapsed, timestamp: Date(), response: "Error: \(error.localizedDescription)"), at: 0) }
            }
        }
    }
}

// MARK: - Private Subviews

private struct RequestBodySection: View {
    @Binding var bodyText: String; let onFormat: () -> Void
    var body: some View {
        Section("Request Body") {
            TextEditor(text: $bodyText).font(.system(.caption2, design: .monospaced)).frame(minHeight: 120).padding(4).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
            HStack { Button(action: onFormat) { Label("Format JSON", systemImage: "text.alignleft").font(.caption2) }.buttonStyle(.bordered).controlSize(.mini); Spacer(); Text("\(bodyText.count) chars").font(.system(size: 8)).foregroundStyle(.tertiary) }
        }
    }
}

private struct HeadersSection: View {
    @Binding var headers: [ConnectorTestConsoleView.HeaderEntry]
    var body: some View {
        Section("Custom Headers") {
            ForEach($headers) { $h in HStack { TextField("Key", text: $h.key).font(.caption.monospaced()); Text(":"); TextField("Value", text: $h.value).font(.caption.monospaced()) } }.onDelete { headers.remove(atOffsets: $0) }
            Button { headers.append(.init(key: "", value: "")) } label: { Label("Add Header", systemImage: "plus.circle.fill").font(.caption.bold()) }
        }
    }
}

private struct TestHistorySection: View {
    let history: [ConnectorTestConsoleView.TestRequest]; let onSelect: (ConnectorTestConsoleView.TestRequest) -> Void
    var body: some View {
        Section("Request History") {
            if history.isEmpty { Text("No requests made.").font(.caption).foregroundStyle(.secondary) }
            else { ForEach(history) { req in Button { onSelect(req) } label: { HStack { Text(req.method).font(.system(size: 7, weight: .black)).padding(4).background(Color.accentColor.opacity(0.1), in: Capsule()); Text(req.endpoint).font(.system(size: 8, design: .monospaced)).lineLimit(1); Spacer(); if let code = req.statusCode { Text("\(code)").font(.system(size: 8, weight: .bold)).foregroundStyle(code < 300 ? Color.green : Color.red) } } } } }
        }
    }
}

private struct ResponseMetricsHeader: View {
    let code: Int?; let time: TimeInterval?; let type: String
    var body: some View {
        if code != nil {
            HStack(spacing: 12) {
                if let c = code { Text("HTTP \(c)").font(.system(size: 8, weight: .black)).padding(.horizontal, 6).padding(.vertical, 2).background((c < 300 ? Color.green : .red).opacity(0.1), in: Capsule()).foregroundStyle(c < 300 ? Color.green : Color.red) }
                if let t = time { Label(String(format: "%.0fms", t * 1000), systemImage: "timer").font(.system(size: 8)).foregroundStyle(.secondary) }
                Spacer(); if !type.isEmpty { Text(type).font(.system(size: 8)).foregroundStyle(.tertiary) }
            }.padding(.vertical, 4)
        }
    }
}

private struct CurlExportSheet: View {
    let cmd: String; @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            ScrollView { Text(cmd).font(.system(.caption2, design: .monospaced)).padding().frame(maxWidth: .infinity, alignment: .leading).background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8)).padding() }
            .navigationTitle("cURL Command").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Copy") { UIPasteboard.general.string = cmd } }; ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}
