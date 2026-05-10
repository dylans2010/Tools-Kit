

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
        List {
            Section("Endpoints (\(filteredRoutes.count))") {
                ForEach(filteredRoutes) { route in
                    Button {
                        testPath = route.path
                        testMethod = route.method
                    } label: {
                        HStack {
                            MethodBadge(method: route.method)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(route.path).font(.subheadline.monospaced())
                                Text(route.module).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Test Console") {
                HStack {
                    Picker("Method", selection: $testMethod) {
                        ForEach(SDKRoute.Method.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)

                    TextField("/path", text: $testPath)
                        .font(.body.monospaced())
                        .textInputAutocapitalization(.never)
                }

                TextField("Parameters (key=value&key2=value2)", text: $testParams)
                    .font(.caption.monospaced())

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

            if let result = testResult {
                Section("Response") {
                    LabeledContent("Status") {
                        Text(result.status.rawValue)
                            .foregroundStyle(result.isSuccess ? Color.green : Color.red).bold()
                    }
                    LabeledContent("Latency", value: "\(Int(result.latency * 1000))ms")

                    if !result.data.isEmpty {
                        ForEach(result.data.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(key).font(.caption2.bold()).foregroundStyle(.secondary)
                                Text(value).font(.caption.monospaced())
                            }
                        }
                    }

                    if let error = result.error {
                        Text(error).font(.caption).foregroundStyle(.red)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search endpoints")
        .navigationTitle("API Explorer")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Picker("Module", selection: $selectedModule) {
                    ForEach(modules, id: \.self) { Text($0.capitalized).tag($0) }
                }
            }
        }
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
                await MainActor.run { testResult = SDKResponse(requestId: request.id, status: .error, error: error.localizedDescription); isTesting = false }
            }
        }
    }

    private func parseParams(_ raw: String) -> [String: String] {
        guard !raw.isEmpty else { return [:] }
        var result: [String: String] = [:]
        for pair in raw.components(separatedBy: "&") {
            let parts = pair.components(separatedBy: "=")
            if parts.count == 2 { result[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces) }
        }
        return result
    }
}

private struct MethodBadge: View {
    let method: SDKRoute.Method
    var body: some View {
        Text(method.rawValue)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
            .foregroundStyle(color)
            .frame(width: 44)
    }
    private var color: Color {
        switch method { case .get: return .blue; case .post: return .green; case .put: return .orange; case .delete: return .red }
    }
}
