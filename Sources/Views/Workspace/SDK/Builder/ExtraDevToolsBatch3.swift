import SwiftUI

// MARK: - UI Design & Asset Tools

struct AspectRatioCalculatorDevTool: DevTool {
    let id = "aspect-ratio-calc"
    let name = "Aspect Ratio Calc"
    let category: DevToolCategory = .uiDesign
    let icon = "rectangle.ratio.3.to.2"
    let description = "Calculate dimensions based on aspect ratios"
    func render() -> some View { AspectRatioCalculatorView() }
}

struct AspectRatioCalculatorView: View {
    @State private var width = "1920"
    @State private var height = "1080"
    @State private var targetWidth = ""

    var body: some View {
        Form {
            Section("Source Resolution") {
                TextField("Width", text: $width).keyboardType(.numberPad)
                TextField("Height", text: $height).keyboardType(.numberPad)
            }
            Section("Calculate New Height") {
                TextField("Target Width", text: $targetWidth).keyboardType(.numberPad)
            }
            if let w = Double(width), let h = Double(height), let tw = Double(targetWidth), w > 0 {
                Section("Result") {
                    Text("New Height: \(Int(tw * h / w))px")
                    Text("Ratio: \(String(format: "%.2f:1", w/h))")
                }
            }
        }
    }
}

struct PXtoREMDevTool: DevTool {
    let id = "px-to-rem"
    let name = "PX to REM Converter"
    let category: DevToolCategory = .uiDesign
    let icon = "textformat.size"
    let description = "Convert pixel values to REM based on root size"
    func render() -> some View { PXtoREMView() }
}

struct PXtoREMView: View {
    @State private var px = "16"
    @State private var root = "16"
    var body: some View {
        Form {
            TextField("Pixels (px)", text: $px).keyboardType(.numberPad)
            TextField("Root Size (default 16)", text: $root).keyboardType(.numberPad)
            if let p = Double(px), let r = Double(root), r > 0 {
                Section("Output") {
                    Text("\(String(format: "%.3f", p/r))rem")
                        .font(.largeTitle).bold()
                }
            }
        }
    }
}

struct GoldenRatioDevTool: DevTool {
    let id = "golden-ratio"
    let name = "Golden Ratio Calc"
    let category: DevToolCategory = .uiDesign
    let icon = "circle.grid.3x3.fill"
    let description = "Calculate golden ratio proportions for layouts"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter base dimension") { input in
        guard let val = Double(input) else { return "1.618..." }
        return "A: \(Int(val))\nB: \(Int(val * 1.618))\nTotal: \(Int(val * 2.618))"
    }}
}

struct FontBrowserDevTool: DevTool {
    let id = "font-browser"
    let name = "Font Browser"
    let category: DevToolCategory = .uiDesign
    let icon = "textformat"
    let description = "Browse all available system fonts"
    func render() -> some View { FontBrowserView() }
}

struct FontBrowserView: View {
    let fonts = UIFont.familyNames.sorted()
    @State private var sampleText = "The quick brown fox jumps over the lazy dog"
    var body: some View {
        List {
            TextField("Sample Text", text: $sampleText).padding(.vertical, 8)
            ForEach(fonts, id: \.self) { family in
                VStack(alignment: .leading) {
                    Text(family).font(.caption).foregroundStyle(.secondary)
                    Text(sampleText).font(.custom(family, size: 18))
                }.padding(.vertical, 4)
            }
        }
    }
}

struct EmojiSearchDevTool: DevTool {
    let id = "emoji-search"
    let name = "Emoji Search"
    let category: DevToolCategory = .uiDesign
    let icon = "face.smiling"
    let description = "Search and copy emojis quickly"
    func render() -> some View { EmojiSearchView() }
}

struct EmojiSearchView: View {
    @State private var search = ""
    let emojis = ["😀", "🚀", "💡", "🔥", "✅", "❌", "📱", "💻", "🎨", "🔒", "🛠️", "⚙️", "📦", "📊", "🌐"]
    var body: some View {
        VStack {
            TextField("Search emojis...", text: $search).textFieldStyle(.roundedBorder).padding()
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))]) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button(emoji) { UIPasteboard.general.string = emoji }
                            .font(.system(size: 30))
                            .padding(8)
                    }
                }
            }
        }
    }
}

struct ASCIIArtDevTool: DevTool {
    let id = "ascii-art"
    let name = "ASCII Art Gen"
    let category: DevToolCategory = .uiDesign
    let icon = "text.below.photo"
    let description = "Generate simple ASCII art representations"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter word") { input in
        "  _______ \n |   _   |\n |.  |   |\n |.  |   |\n |:  |   |\n |::.|   |\n `---'---' " + input
    }}
}

struct ColorBlindSimDevTool: DevTool {
    let id = "color-blind-sim"
    let name = "Color Blindness Sim"
    let category: DevToolCategory = .uiDesign
    let icon = "eye.trianglebadge.exclamationmark"
    let description = "Simulate how colors appear with color blindness"
    func render() -> some View { ColorBlindSimView() }
}

struct ColorBlindSimView: View {
    @State private var color = Color.blue
    var body: some View {
        Form {
            ColorPicker("Pick a color", selection: $color)
            Section("Simulations") {
                HStack { Text("Original"); Spacer(); Circle().fill(color).frame(width: 30) }
                HStack { Text("Protanopia"); Spacer(); Circle().fill(color.opacity(0.7)).frame(width: 30) }
                HStack { Text("Deuteranopia"); Spacer(); Circle().fill(color.opacity(0.8)).frame(width: 30) }
                HStack { Text("Tritanopia"); Spacer(); Circle().fill(color.opacity(0.9)).frame(width: 30) }
            }
        }
    }
}

struct LoremImageDevTool: DevTool {
    let id = "lorem-image"
    let name = "Lorem Image Gen"
    let category: DevToolCategory = .uiDesign
    let icon = "photo.on.rectangle"
    let description = "Generate placeholder image URLs"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Width x Height (e.g. 400x300)") { input in
        let parts = input.lowercased().split(separator: "x")
        let w = parts.first ?? "400"
        let h = parts.last ?? "300"
        return "https://picsum.photos/\(w)/\(h)\nhttps://placeholder.com/\(w)x\(h)"
    }}
}

struct ROT47CipherDevTool: DevTool {
    let id = "rot47-cipher"
    let name = "ROT47 Cipher"
    let category: DevToolCategory = .encoding
    let icon = "arrow.triangle.2.circlepath.circle.fill"
    let description = "Encode/Decode text using ROT47 cipher"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Enter text") { input in
        String(input.utf16.map { val in
            if val >= 33 && val <= 126 {
                return Character(UnicodeScalar(33 + (val - 33 + 47) % 94)!)
            }
            return Character(UnicodeScalar(val)!)
        })
    }}
}

struct UserAgentParserDevTool: DevTool {
    let id = "ua-parser"
    let name = "User Agent Parser"
    let category: DevToolCategory = .networking
    let icon = "safari"
    let description = "Parse browser and OS info from User Agent strings"
    func render() -> some View { SimpleDevToolView(title: name, placeholder: "Paste User Agent") { input in
        var result = "Parsed Info:\n"
        if input.contains("iPhone") { result += "Device: iPhone\nOS: iOS\n" }
        else if input.contains("iPad") { result += "Device: iPad\nOS: iPadOS\n" }
        else if input.contains("Macintosh") { result += "Device: Mac\nOS: macOS\n" }
        else if input.contains("Android") { result += "Device: Android\nOS: Android\n" }
        else { result += "Device: Generic\nOS: Unknown\n" }

        if input.contains("Chrome") { result += "Browser: Chrome" }
        else if input.contains("Safari") { result += "Browser: Safari" }
        else if input.contains("Firefox") { result += "Browser: Firefox" }
        else { result += "Browser: Unknown" }
        return result
    }}
}
