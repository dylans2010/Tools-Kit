import SwiftUI

/// API Explorer — list, inspect, and execute all SDK API endpoints.
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
        List {
            routeListSection
            testConsoleSection
            if let result = testResult {
                testResultSection(result)
            }
        }
        .searchable(text: $searchText, prompt: "Search endpoints")
        .navigationTitle("API Explorer")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Picker("Module", selection: $selectedModule) {
                    ForEach(modules, id: \.self) { mod in
                        Text(mod.capitalized).tag(mod)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    // MARK: - Route List

    private var routeListSection: some View {
        Section {
            ForEach(filteredRoutes) { route in
                Button {
                    testPath = route.path
                    testMethod = route.method
                } label: {
                    HStack {
                        Text(route.method.rawValue)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(methodColor(route.method).opacity(0.15))
                            .foregroundStyle(methodColor(route.method))
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        Text(route.path)
                            .font(.system(.subheadline, design: .monospaced))

                        Spacer()

                        Text(route.module)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Endpoints (\(filteredRoutes.count))")
        }
    }

    // MARK: - Test Console

    private var testConsoleSection: some View {
        Section {
            HStack {
                Picker("Method", selection: $testMethod) {
                    ForEach(SDKRoute.Method.allCases, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
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

            Button {
                executeRequest()
            } label: {
                HStack {
                    if isTesting {
                        ProgressView().controlSize(.small)
                    }
                    Text("Execute")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(testPath.isEmpty || isTesting)
        } header: {
            Text("Test Console")
        }
    }

    // MARK: - Test Result

    private func testResultSection(_ result: SDKResponse) -> some View {
        Section {
            HStack {
                Text("Status")
                Spacer()
                Text(result.status.rawValue)
                    .foregroundStyle(result.isSuccess ? .green : .red)
                    .bold()
            }
            HStack {
                Text("Latency")
                Spacer()
                Text(String(format: "%.1fms", result.latency * 1000))
                    .font(.system(.body, design: .monospaced))
            }
            if !result.data.isEmpty {
                ForEach(result.data.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack {
                        Text(key).font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary)
                        Spacer()
                        Text(value).font(.system(.caption, design: .monospaced))
                    }
                }
            }
            if let error = result.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Response")
        }
    }

    // MARK: - Execute

    private func executeRequest() {
        isTesting = true
        let params = parseParams(testParams)
        let request = SDKRequest(path: testPath, method: testMethod, parameters: params)

        Task {
            do {
                let response = try await SDKRouter.shared.handle(request)
                await MainActor.run {
                    testResult = response
                    isTesting = false
                }
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
