import Foundation
import SwiftUI
import Combine

class ToolRegistry: ObservableObject {
    @Published var tools: [any Tool] = []
    @Published var favoriteToolIDs: Set<String> = []
    @Published var recentlyUsedIDs: [String] = []

    init() {
        registerTools()
        loadPersistedData()
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

            // Advanced Tools
            JSONFormatterTool(),
            APITesterTool(),
            RegexTesterTool(),
            CodeFormatterTool(),
            LogViewerTool(),
            TextSummarizerTool(),
            ExtendedTranslationTool()
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

    private func loadPersistedData() {
        if let favs = UserDefaults.standard.stringArray(forKey: "favoriteToolIDs") {
            favoriteToolIDs = Set(favs)
        }
        if let recent = UserDefaults.standard.stringArray(forKey: "recentlyUsedIDs") {
            recentlyUsedIDs = recent
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
