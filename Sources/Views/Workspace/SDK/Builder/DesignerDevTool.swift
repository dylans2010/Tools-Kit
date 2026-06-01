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

        withAnimation {
            isAnalyzing = true
            errorMessage = nil
            result = nil
        }

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

        withAnimation {
            isAnalyzing = false
        }
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
    @Namespace private var animation

    var body: some View {
        ZStack {
            // Modern Background
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

            LinearGradient(colors: [Color.accentColor.opacity(0.05), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Modern Header Input
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundStyle(.secondary)
                            TextField("https://apple.com", text: $viewModel.urlString)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .keyboardType(.URL)
                        }
                        .padding(12)
                        .background(Color(uiColor: .tertiarySystemBackground))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.1), lineWidth: 1))

                        Button(action: {
                            Task {
                                await viewModel.analyze()
                            }
                        }) {
                            HStack {
                                if viewModel.isAnalyzing {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("Analyze")
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(viewModel.urlString.isEmpty ? Color.gray : Color.accentColor)
                            .cornerRadius(12)
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        .disabled(viewModel.urlString.isEmpty || viewModel.isAnalyzing)
                    }

                    if let error = viewModel.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)

                if let result = viewModel.result {
                    // Modern Tab Picker
                    HStack(spacing: 20) {
                        ForEach(["System", "DESIGN.md", "SwiftUI"].indices, id: \.self) { index in
                            Button(action: { withAnimation(.spring()) { selectedTab = index } }) {
                                VStack(spacing: 8) {
                                    Text(["System", "DESIGN.md", "SwiftUI"][index])
                                        .font(.subheadline.weight(selectedTab == index ? .bold : .medium))
                                        .foregroundStyle(selectedTab == index ? .primary : .secondary)

                                    if selectedTab == index {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.accentColor)
                                            .frame(height: 2)
                                            .matchedGeometryEffect(id: "tab", in: animation)
                                    } else {
                                        Color.clear.frame(height: 2)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            if selectedTab == 0 {
                                designSummary(result)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            } else if selectedTab == 1 {
                                codeView(viewModel.designDoc)
                                    .transition(.opacity)
                            } else {
                                codeView(viewModel.swiftUITokens)
                                    .transition(.opacity)
                            }
                        }
                        .padding()
                    }
                } else if !viewModel.isAnalyzing {
                    VStack(spacing: 24) {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                                .frame(width: 120, height: 120)
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 50))
                                .foregroundStyle(LinearGradient(colors: [.accentColor, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        }

                        VStack(spacing: 8) {
                            Text("Engine Your Design")
                                .font(.title2.bold())
                            Text("Enter a URL to reverse-engineer its visual identity into a production-ready design system.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    }
                } else {
                    VStack(spacing: 20) {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Extracting Design DNA...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Analyzing colors, typography and spacing patterns")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
    }

    @ViewBuilder
    private func designSummary(_ data: DesignSystemResult) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            // Colors Section
            sectionHeader(title: "Color Palette", icon: "paintpalette.fill")

            FlowStack(spacing: 12) {
                ForEach(data.colors) { color in
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(hex: color.hex))
                                .frame(width: 70, height: 70)
                                .shadow(color: Color(hex: color.hex).opacity(0.3), radius: 4, x: 0, y: 2)

                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                .frame(width: 70, height: 70)
                        }

                        VStack(spacing: 2) {
                            Text(color.hex.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .monospaced))

                            if let role = color.role {
                                Text(role)
                                    .font(.system(size: 8))
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(uiColor: .tertiarySystemBackground))
                    .cornerRadius(16)
                }
            }

            // Typography Section
            sectionHeader(title: "Typography", icon: "textformat")

            VStack(spacing: 12) {
                ForEach(data.typography) { font in
                    HStack(spacing: 16) {
                        Text("Aa")
                            .font(.system(size: min(font.size, 32), weight: .medium))
                            .frame(width: 44)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(font.family)
                                .font(.subheadline.bold())
                            Text(font.weight)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(Int(font.size))pt")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundStyle(Color.accentColor)
                            .cornerRadius(6)
                    }
                    .padding()
                    .background(Color(uiColor: .tertiarySystemBackground))
                    .cornerRadius(16)
                }
            }

            // Radius Section
            sectionHeader(title: "Radius Scale", icon: "square.dashed")

            HStack(spacing: 16) {
                ForEach(data.radii, id: \.self) { r in
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: r)
                                .fill(Color.accentColor.opacity(0.1))
                                .frame(width: 50, height: 50)

                            RoundedRectangle(cornerRadius: r)
                                .stroke(Color.accentColor, lineWidth: 1.5)
                                .frame(width: 50, height: 50)
                        }

                        Text("\(Int(r))px")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color(uiColor: .tertiarySystemBackground))
                    .cornerRadius(16)
                }
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .font(.headline)
            Text(title)
                .font(.headline)
            Spacer()
        }
    }

    @ViewBuilder
    private func codeView(_ content: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Generated Implementation", systemImage: "chevron.left.forwardslash.chevron.right")
                    .font(.subheadline.bold())
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = content
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
                }
            }

            ScrollView {
                Text(content)
                    .font(.system(size: 12, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.1), lineWidth: 1))
            }
            .frame(maxHeight: 400)
            .textSelection(.enabled)
        }
        .padding()
        .background(Color(uiColor: .tertiarySystemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}
