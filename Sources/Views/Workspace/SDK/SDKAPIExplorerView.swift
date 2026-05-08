import SwiftUI

struct SDKAPIExplorerView: View {
    @State private var searchText = ""
    @State private var selectedModule = "All"
    @State private var testPath = ""
    @State private var testMethod: SDKRoute.Method = .get
    @State private var testParams: String = ""
    @State private var testResult: SDKResponse?
    @State private var isTesting = false

    private var modules: [String] {
        var mods = Set(SDKRouter.shared.routes().map { $0.module })
        mods.insert("All")
        return mods.sorted()
    }

    private var filteredRoutes: [SDKRoute] {
        SDKRouter.shared.routes().filter { route in
            let matchesModule = selectedModule == "All" || route.module == selectedModule
            let matchesSearch = searchText.isEmpty ||
                route.path.localizedCaseInsensitiveContains(searchText) ||
                route.method.rawValue.localizedCaseInsensitiveContains(searchText)
            return matchesModule && matchesSearch
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                SDKSectionHeader(
                    title: "API Explorer",
                    subtext: "Inspect and test available SDK kernel endpoints.",
                    isCentered: true
                )

                SDKModernCard {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Filter by Module").sdkSubtext()
                            Spacer()
                            Picker("Module", selection: $selectedModule) {
                                ForEach(modules, id: \.self) { Text($0.capitalized).tag($0) }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }

                SDKSectionHeader(title: "Endpoints", subtext: "Live system routes.")
                VStack(spacing: 12) {
                    ForEach(filteredRoutes) { route in
                        Button {
                            testPath = route.path
                            testMethod = route.method
                        } label: {
                            SDKModernCard {
                                HStack(spacing: 12) {
                                    Text(route.method.rawValue)
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(methodColor(route.method).opacity(0.15))
                                        .foregroundStyle(methodColor(route.method))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(route.path).font(.system(.subheadline, design: .monospaced)).bold()
                                        Text(route.module.capitalized).sdkSubtext()
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                SDKSectionHeader(title: "Test Console", subtext: "Execute manual SDK requests.")
                SDKModernCard {
                    VStack(spacing: 16) {
                        HStack {
                            Picker("Method", selection: $testMethod) {
                                ForEach(SDKRoute.Method.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 90)

                            TextField("/path", text: $testPath)
                                .font(.system(.body, design: .monospaced))
                                .textFieldStyle(.roundedBorder)
                        }

                        TextField("key=value&key2=value2", text: $testParams)
                            .font(.system(.caption, design: .monospaced))
                            .textFieldStyle(.roundedBorder)

                        Button(action: executeRequest) {
                            HStack {
                                if isTesting { ProgressView().controlSize(.small) }
                                Text("Execute Request").bold()
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(testPath.isEmpty || isTesting)
                    }
                }

                if let result = testResult {
                    SDKSectionHeader(title: "Response", subtext: "Result from last execution.")
                    SDKModernCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                SDKStatusPill(status: result.isSuccess ? .success : .error, text: result.status.rawValue.uppercased())
                                Spacer()
                                Text(String(format: "%.1fms", result.latency * 1000)).font(.caption.monospaced()).foregroundStyle(.tertiary)
                            }

                            if !result.data.isEmpty {
                                Divider()
                                ForEach(result.data.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                    HStack {
                                        Text(key).font(.system(.caption2, design: .monospaced)).foregroundStyle(.secondary)
                                        Spacer()
                                        Text(value).font(.system(.caption2, design: .monospaced))
                                    }
                                }
                            }

                            if let error = result.error {
                                Divider()
                                Text(error).font(.caption).sdkErrorText()
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("API Explorer")
        .searchable(text: $searchText, prompt: "Search endpoints")
    }

    private func executeRequest() {
        isTesting = true
        let params = parseParams(testParams)
        let request = SDKRequest(path: testPath, method: testMethod, parameters: params)

        Task {
            do {
                let response = try await SDKRouter.shared.handle(request)
                await MainActor.run { testResult = response; isTesting = false }
            } catch {
                await MainActor.run {
                    testResult = SDKResponse(requestId: request.id, status: .error, error: error.localizedDescription)
                    isTesting = false
                }
            }
        }
    }

    private func parseParams(_ raw: String) -> [String: String] {
        guard !raw.isEmpty else { return [:] }
        var result: [String: String] = [:]
        for pair in raw.components(separatedBy: "&") {
            let parts = pair.components(separatedBy: "=")
            if parts.count == 2 {
                result[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        return result
    }

    private func methodColor(_ method: SDKRoute.Method) -> Color {
        switch method {
        case .get: return .blue
        case .post: return .green
        case .put: return .orange
        case .delete: return .red
        }
    }
}
