import SwiftUI
import Combine

// MARK: - Models

struct DesignSystemResult: Codable {
    let title: String
    let colors: [ExtractedColor]
    let typography: [ExtractedFont]
    let radii: [CGFloat]
    let screenshotBase64: String?
    let layoutHints: [String]?

    struct ExtractedColor: Codable, Identifiable {
        var id: String { hex }
        let hex: String
        let role: String? // primary, secondary, background, etc.
    }

    struct ExtractedFont: Codable, Identifiable {
        var id: String { family + "\(size)" }
        let family: String
        let size: CGFloat
        let weight: String
    }
}

// MARK: - Tool Implementation

struct DesignerDevTool: DevTool {
    let id = "designer-engine"
    let name = "Designer"
    let category: DevToolCategory = .uiDesign
    let icon = "wand.and.stars"
    let description = "Reverse-engineer any website into a SwiftUI design system"

    func render() -> some View {
        DesignerView()
    }
}

// MARK: - View Model

@MainActor
class DesignerViewModel: ObservableObject {
    @Published var urlString: String = ""
    @Published var isAnalyzing: Bool = false
    @Published var result: DesignSystemResult?
    @Published var errorMessage: String?
    @Published var designDoc: String = ""
    @Published var swiftUITokens: String = ""

    private let analyzeURL = URL(string: "http://50.21.181.105:4000/analyze")!

    func analyze() async {
        guard let url = URL(string: urlString), url.scheme != nil else {
            errorMessage = "Invalid URL"
            return
        }

        isAnalyzing = true
        errorMessage = nil
        result = nil

        do {
            var request = URLRequest(url: analyzeURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body = ["url": urlString]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let decodedResult = try JSONDecoder().decode(DesignSystemResult.self, from: data)
            self.result = decodedResult

            // Normalize with AI
            await generateDesignSystem(from: decodedResult)

        } catch {
            errorMessage = "Analysis failed: \(error.localizedDescription)"
        }

        isAnalyzing = false
    }

    private func generateDesignSystem(from data: DesignSystemResult) async {
        let ai = AIService.shared

        let prompt = """
        Analyze the following extracted website design data and generate:
        1. A production-ready DESIGN.md explaining the design system.
        2. A SwiftUI extension on Color and Font containing these tokens.

        Extracted Data:
        Title: \(data.title)
        Colors: \(data.colors.map { "\($0.hex) (\($0.role ?? "unknown"))" }.joined(separator: ", "))
        Typography: \(data.typography.map { "\($0.family) \($0.size)pt \($0.weight)" }.joined(separator: ", "))
        Corner Radii: \(data.radii.map { "\($0)pt" }.joined(separator: ", "))
        Layout Hints: \(data.layoutHints?.joined(separator: ", ") ?? "none")

        Return the result in two distinct blocks clearly marked with [DESIGN.MD] and [SWIFTUI_TOKENS].
        """

        do {
            let aiResponse = try await ai.processText(prompt: prompt, systemPrompt: "You are a design system engineer. Output only the requested blocks based on real data.")

            if let docRange = aiResponse.range(of: "[DESIGN.MD]"),
               let tokensRange = aiResponse.range(of: "[SWIFTUI_TOKENS]") {

                let docPart = aiResponse[docRange.upperBound..<tokensRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                let tokensPart = aiResponse[tokensRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)

                self.designDoc = docPart
                self.swiftUITokens = tokensPart
            } else {
                self.designDoc = aiResponse
            }
        } catch {
            self.designDoc = "AI normalization failed, but raw data is available above."
        }
    }
}

// MARK: - UI

struct DesignerView: View {
    @StateObject private var viewModel = DesignerViewModel()
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header Input
            VStack(spacing: 12) {
                HStack {
                    TextField("Enter website URL (e.g. https://apple.com)", text: $viewModel.urlString)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)

                    Button(action: {
                        Task { await viewModel.analyze() }
                    }) {
                        if viewModel.isAnalyzing {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Analyze")
                                .bold()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.urlString.isEmpty || viewModel.isAnalyzing)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))

            if let result = viewModel.result {
                Picker("View", selection: $selectedTab) {
                    Text("System").tag(0)
                    Text("DESIGN.md").tag(1)
                    Text("SwiftUI").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if selectedTab == 0 {
                            designSummary(result)
                        } else if selectedTab == 1 {
                            codeView(viewModel.designDoc)
                        } else {
                            codeView(viewModel.swiftUITokens)
                        }
                    }
                    .padding()
                }
            } else if !viewModel.isAnalyzing {
                ContentUnavailableView(
                    "Ready to Engine",
                    systemImage: "browser.display",
                    description: Text("Enter a URL to extract its design DNA.")
                )
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Reverse-engineering styles...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private func designSummary(_ data: DesignSystemResult) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Colors
            VStack(alignment: .leading, spacing: 12) {
                Text("Color Palette")
                    .font(.headline)

                FlowLayout(spacing: 10) {
                    ForEach(data.colors) { color in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: color.hex))
                                .frame(width: 60, height: 60)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.1), lineWidth: 1))

                            Text(color.hex.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .monospaced))

                            if let role = color.role {
                                Text(role)
                                    .font(.system(size: 8))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Divider()

            // Typography
            VStack(alignment: .leading, spacing: 12) {
                Text("Typography")
                    .font(.headline)

                ForEach(data.typography) { font in
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading) {
                            Text("Aa")
                                .font(.system(size: font.size))
                            Text("\(font.family) (\(font.weight))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(Int(font.size))pt")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Divider()

            // Radius
            VStack(alignment: .leading, spacing: 12) {
                Text("Radius Scale")
                    .font(.headline)

                HStack(spacing: 15) {
                    ForEach(data.radii, id: \.self) { r in
                        VStack {
                            RoundedRectangle(cornerRadius: r)
                                .stroke(Color.accentColor, lineWidth: 2)
                                .frame(width: 40, height: 40)
                            Text("\(Int(r))")
                                .font(.system(size: 10, design: .monospaced))
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func codeView(_ content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Generated Implementation")
                    .font(.subheadline.bold())
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = content
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
            }

            Text(content)
                .font(.system(size: 12, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(8)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Helpers

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Generic Flow Layout for tags/palette
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, point) in result.offsets.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var offsets: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if currentX + size.width > maxWidth {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                offsets.append(CGPoint(x: currentX, y: currentY))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}
