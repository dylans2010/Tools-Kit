import SwiftUI
import Compression

// MARK: - System & Debugging Tools

struct EnvVarDevTool: DevTool {
    let id = "env-vars"
    let name = "Env Variables"
    let category: DevToolCategory = .system
    let icon = "terminal"
    let description = "List current process environment variables"
    func render() -> some View { EnvVarListView() }
}

struct EnvVarListView: View {
    let env = ProcessInfo.processInfo.environment
    var body: some View {
        List {
            ForEach(env.keys.sorted(), id: \.self) { key in
                VStack(alignment: .leading) {
                    Text(key).font(.caption).bold()
                    Text(env[key] ?? "").font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct ScreenInfoDevTool: DevTool {
    let id = "screen-info"
    let name = "Screen Info"
    let category: DevToolCategory = .system
    let icon = "display"
    let description = "Inspect screen resolution, scale, and safe areas"
    func render() -> some View { ScreenInfoView() }
}

struct ScreenInfoView: View {
    var body: some View {
        List {
            Section("Display") {
                LabeledContent("Main Screen", value: "\(Int(UIScreen.main.bounds.width)) x \(Int(UIScreen.main.bounds.height))")
                LabeledContent("Scale", value: "\(UIScreen.main.scale)x")
                LabeledContent("Native Scale", value: "\(UIScreen.main.nativeScale)x")
                LabeledContent("Brightness", value: "\(Int(UIScreen.main.brightness * 100))%")
            }
        }
    }
}

struct HardwareDetailsDevTool: DevTool {
    let id = "hardware-details"
    let name = "Hardware Details"
    let category: DevToolCategory = .system
    let icon = "cpu.fill"
    let description = "Hardware specific details and capabilities"
    func render() -> some View { HardwareDetailsView() }
}

struct HardwareDetailsView: View {
    var body: some View {
        List {
            LabeledContent("Processors", value: "\(ProcessInfo.processInfo.activeProcessorCount)")
            LabeledContent("Physical Memory", value: "\(ProcessInfo.processInfo.physicalMemory / 1024 / 1024 / 1024) GB")
            LabeledContent("Thermal State", value: "\(ProcessInfo.processInfo.thermalState.rawValue)")
            LabeledContent("Low Power Mode", value: ProcessInfo.processInfo.isLowPowerModeEnabled ? "On" : "Off")
        }
    }
}

struct ReflectionExplorerDevTool: DevTool {
    let id = "reflection-explorer"
    let name = "Reflection Explorer"
    let category: DevToolCategory = .debugging
    let icon = "magnifyingglass.circle.fill"
    let description = "Explore object properties using Swift Reflection"
    func render() -> some View { ReflectionExplorerView() }
}

struct ReflectionExplorerView: View {
    @State private var output = ""
    var body: some View {
        Form {
            Button("Reflect ProcessInfo") {
                let mirror = Mirror(reflecting: ProcessInfo.processInfo)
                output = mirror.children.map { "\($0.label ?? "unknown"): \($0.value)" }.joined(separator: "\n")
            }
            if !output.isEmpty {
                Section("Output") {
                    Text(output).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                }
            }
        }
    }
}

struct SideBySideDiffDevTool: DevTool {
    let id = "side-diff"
    let name = "Side-by-Side Diff"
    let category: DevToolCategory = .utilities
    let icon = "doc.split"
    let description = "Compare two text blocks side-by-side"
    func render() -> some View { SideBySideDiffView() }
}

struct SideBySideDiffView: View {
    @State private var text1 = ""
    @State private var text2 = ""
    var body: some View {
        VStack {
            HStack {
                TextEditor(text: $text1).border(Color.gray.opacity(0.2))
                TextEditor(text: $text2).border(Color.gray.opacity(0.2))
            }.frame(maxHeight: 300)
            List {
                Section("Analysis") {
                    Text("Length 1: \(text1.count)")
                    Text("Length 2: \(text2.count)")
                    Text("Matches: \(text1 == text2 ? "YES" : "NO")")
                }
            }
        }
    }
}

struct ZlibCompressDevTool: DevTool {
    let id = "zlib-compress"
    let name = "Zlib Compressor"
    let category: DevToolCategory = .encoding
    let icon = "archivebox"
    let description = "Compress text using Zlib algorithm"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Text to compress") { input in
        guard let data = input.data(using: .utf8) else { return "Encoding error" }
        var buffer = [UInt8](repeating: 0, count: data.count + 1024)
        let size = buffer.withUnsafeMutableBufferPointer { (destPtr: inout UnsafeMutableBufferPointer<UInt8>) -> Int in
            data.withUnsafeBytes { (srcPtr: UnsafeRawBufferPointer) -> Int in
                compression_encode_buffer(destPtr.baseAddress!, destPtr.count, srcPtr.baseAddress!.assumingType(of: UInt8.self), srcPtr.count, nil, COMPRESSION_ZLIB)
            }
        }
        guard size > 0 else { return "Compression failed" }
        return Data(buffer.prefix(size)).base64EncodedString()
    }}
}

struct GzipCompressDevTool: DevTool {
    let id = "gzip-compress"
    let name = "Gzip Compressor"
    let category: DevToolCategory = .encoding
    let icon = "archivebox.fill"
    let description = "Compress text using Gzip algorithm"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Text to compress") { input in
        guard let data = input.data(using: .utf8) else { return "Encoding error" }
        var buffer = [UInt8](repeating: 0, count: data.count + 1024)
        let size = buffer.withUnsafeMutableBufferPointer { (destPtr: inout UnsafeMutableBufferPointer<UInt8>) -> Int in
            data.withUnsafeBytes { (srcPtr: UnsafeRawBufferPointer) -> Int in
                compression_encode_buffer(destPtr.baseAddress!, destPtr.count, srcPtr.baseAddress!.assumingType(of: UInt8.self), srcPtr.count, nil, COMPRESSION_GZIP)
            }
        }
        guard size > 0 else { return "Compression failed" }
        return Data(buffer.prefix(size)).base64EncodedString()
    }}
}

struct Base64ImagePreviewDevTool: DevTool {
    let id = "b64-img-preview"
    let name = "B64 Image Preview"
    let category: DevToolCategory = .encoding
    let icon = "photo"
    let description = "Preview images from Base64 strings"
    func render() -> some View { Base64ImagePreviewView() }
}

struct Base64ImagePreviewView: View {
    @State private var b64 = ""
    var body: some View {
        Form {
            Section("Base64 String") {
                TextEditor(text: $b64).frame(height: 100)
            }
            if let data = Data(base64Encoded: b64), let uiImage = UIImage(data: data) {
                Section("Preview") {
                    Image(uiImage: uiImage).resizable().scaledToFit()
                }
            }
        }
    }
}

struct UnicodeNormalizerDevTool: DevTool {
    let id = "unicode-norm"
    let name = "Unicode Normalizer"
    let category: DevToolCategory = .utilities
    let icon = "textformat.abc"
    let description = "Normalize Unicode strings (NFC, NFD, NFKC, NFKD)"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter text") { $0.precomposedStringWithCanonicalMapping }}
}

struct JSMinifierDevTool: DevTool {
    let id = "js-minifier"
    let name = "JS Minifier"
    let category: DevToolCategory = .data
    let icon = "scissors"
    let description = "Minify JavaScript by removing comments and spaces"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Paste JS") { input in
        input.replacingOccurrences(of: "//.*", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }}
}
