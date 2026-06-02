import SwiftUI

struct Base32ConverterDevTool: DevTool {
    let id = "base32-converter"
    let name = "Base32 Encoder/Decoder"
    let category: DevToolCategory = .encoding
    let icon = "text.and.command.macwindow"
    let description = "Encode and decode text using Base32 (RFC 4648)"

    func render() -> some View {
        Base32ConverterView()
    }
}

struct Base32ConverterView: View {
    @State private var input = ""
    @State private var output = ""
    @State private var mode: Base32Mode = .encode

    enum Base32Mode { case encode, decode }

    private let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")

    var body: some View {
        Form {
            Picker("Mode", selection: $mode) {
                Text("Encode").tag(Base32Mode.encode)
                Text("Decode").tag(Base32Mode.decode)
            }.pickerStyle(.segmented)

            Section("Input") {
                TextEditor(text: $input)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 100)
            }

            Button("Convert") {
                if mode == .encode { encode() } else { decode() }
            }
            .frame(maxWidth: .infinity)

            if !output.isEmpty {
                Section("Output") {
                    Text(output)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
    }

    private func encode() {
        let data = input.data(using: .utf8)!
        var result = ""
        var bits = 0
        var val = 0
        for byte in data {
            val = (val << 8) | Int(byte)
            bits += 8
            while bits >= 5 {
                result.append(alphabet[(val >> (bits - 5)) & 31])
                bits -= 5
            }
        }
        if bits > 0 {
            result.append(alphabet[(val << (5 - bits)) & 31])
        }
        while result.count % 8 != 0 { result.append("=") }
        output = result
    }

    private func decode() {
        let cleaned = input.uppercased().replacingOccurrences(of: "=", with: "")
        var data = Data()
        var bits = 0
        var val = 0
        for char in cleaned {
            guard let index = alphabet.firstIndex(of: char) else { continue }
            val = (val << 5) | index
            bits += 5
            if bits >= 8 {
                data.append(UInt8((val >> (bits - 8)) & 255))
                bits -= 8
            }
        }
        output = String(data: data, encoding: .utf8) ?? "Decoding error"
    }
}
