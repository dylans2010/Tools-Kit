import SwiftUI
import MachO

struct Diag_RuntimeInfoView: View {
    @State private var loadedLibraries: [LibraryInfo] = []
    @State private var searchText: String = ""
    @State private var environmentVars: [EnvEntry] = []

    struct LibraryInfo: Identifiable {
        let id = UUID()
        let name: String
        let path: String
        let isSystem: Bool
    }

    struct EnvEntry: Identifiable {
        let id = UUID()
        let key: String
        let value: String
    }

    var filteredLibraries: [LibraryInfo] {
        if searchText.isEmpty { return loadedLibraries }
        let query = searchText.lowercased()
        return loadedLibraries.filter { $0.name.lowercased().contains(query) }
    }

    var body: some View {
        Form {
            Section("Swift Runtime") {
                #if swift(>=5.9)
                LabeledContent("Swift Version") { Text("5.9+") }
                #elseif swift(>=5.8)
                LabeledContent("Swift Version") { Text("5.8") }
                #else
                LabeledContent("Swift Version") { Text("5.x") }
                #endif
                LabeledContent("Objective-C Runtime") { Text("Available") }
                LabeledContent("ABI Stability") { Text("Stable") }
                LabeledContent("Concurrency") { Text("Swift Concurrency") }
            }

            Section("Process") {
                LabeledContent("Process ID") { Text("\(ProcessInfo.processInfo.processIdentifier)").monospacedDigit() }
                LabeledContent("Process Name") { Text(ProcessInfo.processInfo.processName) }
                LabeledContent("Arguments") { Text("\(ProcessInfo.processInfo.arguments.count)") }
                LabeledContent("Host Name") { Text(ProcessInfo.processInfo.hostName).font(.caption) }
                LabeledContent("OS Version") {
                    let os = ProcessInfo.processInfo.operatingSystemVersion
                    Text("\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)")
                }
            }

            Section("Memory Layout") {
                LabeledContent("Pointer Size") { Text("\(MemoryLayout<UnsafeRawPointer>.size * 8)-bit") }
                LabeledContent("Int Size") { Text("\(MemoryLayout<Int>.size) bytes") }
                LabeledContent("Page Size") { Text("\(vm_kernel_page_size) bytes").monospacedDigit() }
                LabeledContent("Byte Order") {
                    #if _endian(little)
                    Text("Little Endian")
                    #else
                    Text("Big Endian")
                    #endif
                }
            }

            Section {
                if !loadedLibraries.isEmpty {
                    TextField("Search...", text: $searchText)
                        .textInputAutocapitalization(.never)

                    LabeledContent("System") {
                        Text("\(loadedLibraries.filter(\.isSystem).count)")
                    }
                    LabeledContent("App") {
                        Text("\(loadedLibraries.filter { !$0.isSystem }.count)")
                    }

                    ForEach(filteredLibraries.prefix(30)) { lib in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lib.name)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(lib.isSystem ? .secondary : .blue)
                            Text(lib.path)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }
                    if filteredLibraries.count > 30 {
                        Text("... and \(filteredLibraries.count - 30) more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Loaded Libraries (\(loadedLibraries.count))")
            }

            if !environmentVars.isEmpty {
                Section("Environment (\(environmentVars.count) vars)") {
                    ForEach(environmentVars.prefix(20)) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.key)
                                .font(.caption.weight(.medium))
                            Text(entry.value)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
        .navigationTitle("Runtime Info")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadInfo() }
    }

    private func loadInfo() {
        loadLibraries()
        loadEnvironment()
    }

    private func loadLibraries() {
        var libs: [LibraryInfo] = []
        let count = _dyld_image_count()
        for i in 0..<count {
            if let name = _dyld_get_image_name(i) {
                let path = String(cString: name)
                let fileName = (path as NSString).lastPathComponent
                let isSystem = path.hasPrefix("/usr/") || path.hasPrefix("/System/")
                libs.append(LibraryInfo(name: fileName, path: path, isSystem: isSystem))
            }
        }
        loadedLibraries = libs.sorted { $0.name < $1.name }
    }

    private func loadEnvironment() {
        let env = ProcessInfo.processInfo.environment
        environmentVars = env.map { EnvEntry(key: $0.key, value: $0.value) }
            .sorted { $0.key < $1.key }
    }
}
