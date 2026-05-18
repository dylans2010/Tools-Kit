import SwiftUI

struct RuntimeInspectorTool: DevTool {
    let id = UUID()
    let name = "Runtime Inspector"
    let category: DevToolCategory = .debugging
    let icon = "ant"
    let description = "Inspect Objective-C runtime classes"
    func render() -> some View { RuntimeInspectorDevToolView() }
}

struct RuntimeInspectorDevToolView: View {
    @State private var searchText = ""
    @State private var classes: [String] = []
    @State private var selectedClass: String?
    @State private var methods: [String] = []
    @State private var isLoading = false

    var body: some View {
        Form {
            Section {
                Button(action: loadClasses) {
                    HStack {
                        Label("Load Runtime Classes", systemImage: "arrow.clockwise")
                        if isLoading { Spacer(); ProgressView().controlSize(.small) }
                    }
                }
            }
            if !classes.isEmpty {
                Section("Classes (\(filteredClasses.count) of \(classes.count))") {
                    ForEach(filteredClasses.prefix(100), id: \.self) { cls in
                        Button {
                            selectedClass = cls
                            loadMethods(cls)
                        } label: {
                            Text(cls).font(.system(.caption, design: .monospaced))
                        }
                    }
                }
            }
            if let selectedClass, !methods.isEmpty {
                Section("\(selectedClass) Methods (\(methods.count))") {
                    ForEach(methods.prefix(50), id: \.self) { method in
                        Text(method).font(.system(.caption2, design: .monospaced)).textSelection(.enabled)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Filter classes...")
        .navigationTitle("Runtime Inspector")
    }

    private var filteredClasses: [String] {
        if searchText.isEmpty { return Array(classes.prefix(200)) }
        return classes.filter { $0.lowercased().contains(searchText.lowercased()) }
    }

    private func loadClasses() {
        isLoading = true
        DispatchQueue.global().async {
            var count: UInt32 = 0
            guard let classList = objc_copyClassList(&count) else {
                DispatchQueue.main.async { isLoading = false }
                return
            }
            let names = (0..<Int(count)).map { String(cString: class_getName(classList[$0])) }
                .sorted()
            free(UnsafeMutableRawPointer(classList))
            DispatchQueue.main.async {
                classes = names
                isLoading = false
            }
        }
    }

    private func loadMethods(_ className: String) {
        methods.removeAll()
        guard let cls = NSClassFromString(className) else { return }
        var count: UInt32 = 0
        if let methodList = class_copyMethodList(cls, &count) {
            methods = (0..<Int(count)).map { String(cString: sel_getName(method_getName(methodList[$0]))) }.sorted()
            free(methodList)
        }
    }
}
