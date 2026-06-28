import SwiftUI

struct BackupModulePickerView: View {
    @Binding var selectedModules: Set<BackupModule>
    let availableModules: Set<BackupModule>

    var body: some View {
        List {
            ForEach(Array(availableModules).sorted(by: { $0.rawValue < $1.rawValue })) { module in
                Button {
                    if selectedModules.contains(module) {
                        selectedModules.remove(module)
                    } else {
                        selectedModules.insert(module)
                    }
                } label: {
                    HStack {
                        Label(module.rawValue.capitalized, systemImage: moduleIcon(for: module))
                        Spacer()
                        if selectedModules.contains(module) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }
        }
    }

    private func moduleIcon(for module: BackupModule) -> String {
        switch module {
        case .workspace: return "rectangle.3.group"
        case .mail: return "envelope"
        case .sdk: return "hammer"
        case .plugins: return "puzzlepiece.extension"
        case .connectors: return "cable.connector"
        case .calendar: return "calendar"
        case .notes: return "note.text"
        case .tasks: return "checklist"
        case .whiteboards: return "scribble.variable"
        case .files: return "folder"
        case .ai: return "sparkles"
        case .workouts: return "figure.run"
        case .music: return "music.note"
        case .analytics: return "chart.bar"
        case .system_state: return "gearshape"
        case .ui_state: return "iphone"
        }
    }
}
