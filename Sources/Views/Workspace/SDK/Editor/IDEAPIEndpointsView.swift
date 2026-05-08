import SwiftUI

struct IDEAPIEndpointsView: View {
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
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("API Explorer").font(.headline)
                            Text("Inspect and test all SDK internal and external endpoints.").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        SDKStatusPill("\(filteredRoutes.count) ROUTES", systemImage: "network", color: .blue)
                    }

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Search endpoints...", text: $searchText)
                            .font(.subheadline)

                        Picker("Module", selection: $selectedModule) {
                            ForEach(modules, id: \.self) { mod in
                                Text(mod.capitalized).tag(mod)
                            }
                        }
                        .pickerStyle(.menu)
                        .font(.caption)
                    }
                    .padding(8)
                    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                }
                .padding(.vertical, 8)
            } header: {
                SDKSectionHeader("Routes", subtitle: "Internal SDK endpoint registry", systemImage: "arrow.up.right.circle.fill")
            }

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
                SDKSectionHeader("Endpoints", subtitle: "Callable system routes", alignment: .leading)
            }

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
                        Text("Execute Request")
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(testPath.isEmpty || isTesting)
            } header: {
                SDKSectionHeader("Test Console", subtitle: "Live endpoint execution", systemImage: "terminal.fill")
            }

            if let result = testResult {
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
                } header: {
                    SDKSectionHeader("Response", subtitle: "Execution payload", alignment: .leading)
                }
            }
        }
        .navigationTitle("API Explorer")
    }

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
