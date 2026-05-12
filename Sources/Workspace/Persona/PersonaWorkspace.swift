import Foundation

/// Defines the Persona Workspace configuration and indexing logic.
struct PersonaWorkspace: @unchecked Sendable {
    var config: PersonaConfig

    func indexWorkspace() async {
        // Implementation for indexing documents and creating embeddings
        // This would interact with EmbeddingService
        print("Indexing workspace with persona configuration: \(config.name)")
    }

    @MainActor
    static func gatherFullWorkspaceData() -> String {
        var fullData: [String: Any] = [:]
        let isoFormatter = ISO8601DateFormatter()

        // 1. Mail
        fullData["mail_accounts"] = AccountManager.shared.accounts.map { account in
            ["email": account.emailAddress, "provider": account.providerType.rawValue, "name": account.displayName]
        }

        // 2. Articles
        fullData["article_collections"] = ArticlesManager.shared.collections.map { collection in
            ["name": collection.name, "articles": collection.articles.map { $0.title }]
        }

        // 3. Calendar
        fullData["calendar_events"] = CalendarManager.shared.events.map { event in
            [
                "title": event.title,
                "date": isoFormatter.string(from: event.date),
                "start": isoFormatter.string(from: event.startTime),
                "end": isoFormatter.string(from: event.endTime),
                "description": event.description
            ]
        }

        // 4. Habits
        fullData["habits"] = HabitsManager.shared.habits.map { habit in
            ["name": habit.name, "streak": habit.currentStreak, "target": habit.targetCount]
        }

        // 5. Slides
        fullData["slide_decks"] = SlideDecksManager.shared.decks.map { deck in
            ["title": deck.title, "slides_count": deck.slides.count]
        }

        // 6. Sheets
        fullData["spreadsheets"] = SpreadsheetsManager.shared.spreadsheets.map { sheet in
            ["name": sheet.name, "rows": sheet.cells.count, "columns": sheet.cells.first?.count ?? 0]
        }

        // 7. Collaboration
        fullData["collaboration_spaces"] = CollaborationManager.shared.spaces.map { space in
            ["name": space.name, "description": space.description, "members_count": space.members.count]
        }

        // 8. Tasks
        fullData["tasks"] = TasksManager.shared.tasks.map { task in
            ["title": task.title, "completed": task.completed, "priority": task.priority.rawValue]
        }

        // 9. Notebooks
        fullData["notebooks"] = NotebooksManager.shared.notebooks.map { notebook in
            ["name": notebook.name, "folders": notebook.folders.map { folder in
                ["name": folder.name, "pages": folder.pages.map { $0.title }]
            }]
        }

        // 10. Forms
        fullData["forms"] = FormsBackend.shared.forms.map { form in
            ["name": form.name, "questions_count": form.questions.count]
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: fullData, options: [.prettyPrinted, .sortedKeys])
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            return "{ \"error\": \"Failed to encode workspace data: \(error.localizedDescription)\" }"
        }
    }
}
