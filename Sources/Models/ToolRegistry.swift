import Foundation
import SwiftUI
import Combine

class ToolRegistry: ObservableObject {
    @Published var tools: [any Tool] = []
    @Published var favoriteToolIDs: Set<String> = []
    @Published var recentlyUsedIDs: [String] = []
    @Published var installedToolIDs: Set<String> = []

    init() {
        registerTools()
        loadPersistedData()

        // Mark all non-API tools as installed by default
        for tool in tools {
            if !tool.requiresAPI {
                installedToolIDs.insert(tool.id)
            }
        }
    }

    private func registerTools() {
        self.tools = [
            // Basic Tools
            CalculatorTool(),
            UnitConverterTool(),
            CurrencyConverterTool(),
            TimezoneConverterTool(),
            QRCodeTool(),
            PasswordGeneratorTool(),
            NotesFormatterTool(),
            ClipboardManagerTool(),
            ColorPickerTool(),
            Base64Tool(),
            FileSizeTool(),
            RealTimeTranslationTool(),
            WordCounterTool(),
            TextFormatterTool(),
            PasswordStrengthTool(),
            MetadataRemoverTool(),

            // Advanced Tools
            JSONFormatterTool(),
            APITesterTool(),
            RegexTesterTool(),
            CodeFormatterTool(),
            LogViewerTool(),
            TextSummarizerTool(),
            ExtendedTranslationTool(),
            NotesTool(),
            FileConverterTool(),
            PDFTools(),
            OCRTool(),
            ImageProcessorTool(),
            MeetingNotesTool(),
            JWTDecoderTool(),
            HashGeneratorTool(),
            DiffCheckerTool(),
            XMLFormatterTool(),
            SQLFormatterTool(),
            WebhookTesterTool(),
            SecureNotesTool(),
            EncryptionTool(),
            IPInfoTool(),
            DNSLookupTool(),
            PortCheckerTool(),
            WebsiteScreenshotTool(),
            LinkPreviewTool(),
            HTTPInspectorTool(),
            TextRewriterTool(),
            CodeExplainerTool(),
            PromptGeneratorTool(),
            EmailGeneratorTool(),
            IdeaGeneratorTool(),
            WeatherTool()
        ]
    }

    func toggleFavorite(toolID: String) {
        if favoriteToolIDs.contains(toolID) {
            favoriteToolIDs.remove(toolID)
        } else {
            favoriteToolIDs.insert(toolID)
        }
        saveFavorites()
    }

    func markAsUsed(toolID: String) {
        recentlyUsedIDs.removeAll { $0 == toolID }
        recentlyUsedIDs.insert(toolID, at: 0)
        if recentlyUsedIDs.count > 5 {
            recentlyUsedIDs.removeLast()
        }
        saveRecentlyUsed()
    }

    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteToolIDs), forKey: "favoriteToolIDs")
    }

    private func saveRecentlyUsed() {
        UserDefaults.standard.set(recentlyUsedIDs, forKey: "recentlyUsedIDs")
    }

    private func saveInstalledTools() {
        UserDefaults.standard.set(Array(installedToolIDs), forKey: "installedToolIDs")
    }

    private func loadPersistedData() {
        if let favs = UserDefaults.standard.stringArray(forKey: "favoriteToolIDs") {
            favoriteToolIDs = Set(favs)
        }
        if let recent = UserDefaults.standard.stringArray(forKey: "recentlyUsedIDs") {
            recentlyUsedIDs = recent
        }
        if let installed = UserDefaults.standard.stringArray(forKey: "installedToolIDs") {
            installedToolIDs = Set(installed)
        }
    }

    func installTool(toolID: String) {
        // Simulate a download delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.installedToolIDs.insert(toolID)
            self.saveInstalledTools()
        }
    }

    var basicTools: [any Tool] {
        tools.filter { $0.complexity == .basic }
    }

    var advancedTools: [any Tool] {
        tools.filter { $0.complexity == .advanced }
    }

    func filteredTools(query: String) -> [any Tool] {
        if query.isEmpty {
            return tools
        }
        return tools.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.description.localizedCaseInsensitiveContains(query) }
    }
}
