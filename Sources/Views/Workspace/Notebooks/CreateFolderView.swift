import SwiftUI

struct CreateFolderView: View {
    let notebookID: UUID
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = NotebooksManager.shared
    @State private var name = ""
    @State private var selectedTemplate: FolderTemplate?

    enum FolderTemplate: String, CaseIterable, Identifiable {
        case project = "Project Workspace"
        case meeting = "Meeting Notes"
        case research = "Research Hub"
        case planning = "Product Planning"
        case journal = "Journal"
        case recipes = "Recipes"
        case snippets = "Code Snippets"
        case course = "Course Study"
        case fitness = "Fitness Tracker"
        case finance = "Personal Finance"
        case travel = "Travel Planner"
        case inventory = "Inventory"
        case reading = "Reading List"
        case dream = "Dream Journal"
        case client = "Client Wiki"
        case brand = "Brand Guidelines"
        case lecture = "Lecture Notes"
        case wiki = "Personal Wiki"
        case budget = "Budget Tracker"
        case trip = "Trip Planner"
        case habit = "Habit Tracker"
        case workout = "Workout Log"
        case contacts = "Contact List"
        case inventory2 = "Home Inventory"
        case ideas = "Idea Bank"
        case tasks = "Task Master"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .project: return "briefcase.fill"
            case .meeting: return "video.fill"
            case .research: return "lightbulb.fill"
            case .planning: return "calendar.fill"
            case .journal: return "book.fill"
            case .recipes: return "fork.knife"
            case .snippets: return "chevron.left.forwardslash.chevron.right"
            case .course: return "graduationcap.fill"
            case .fitness: return "figure.run"
            case .finance: return "dollarsign.circle.fill"
            case .travel: return "airplane"
            case .inventory: return "archivebox.fill"
            case .reading: return "book.closed.fill"
            case .dream: return "moon.stars.fill"
            case .client: return "person.2.fill"
            case .brand: return "paintpalette.fill"
            case .lecture: return "doc.text.fill"
            case .wiki: return "network"
            case .budget: return "creditcard.fill"
            case .trip: return "map.fill"
            case .habit: return "checkmark.circle.fill"
            case .workout: return "dumbbell.fill"
            case .contacts: return "person.crop.circle.fill"
            case .inventory2: return "house.fill"
            case .ideas: return "lightbulb.circle.fill"
            case .tasks: return "checklist"
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Enter Folder Name", text: $name)
                } header: {
                    Text("Folder Name")
                }

                Section {
                    ForEach(FolderTemplate.allCases) { template in
                        Button(action: { selectedTemplate = template; name = template.rawValue }) {
                            HStack {
                                Label(template.rawValue, systemImage: template.icon)
                                Spacer()
                                if selectedTemplate == template {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                } header: {
                    Text("Templates")
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let folderName = n.isEmpty ? "New Folder" : n
                        guard let folder = manager.addFolder(to: notebookID, name: folderName) else {
                            dismiss()
                            return
                        }

                        // Apply template if selected
                        if let template = selectedTemplate {
                            applyTemplate(template, to: folder.id)
                        }

                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func applyTemplate(_ template: FolderTemplate, to folderID: UUID) {
        switch template {
        case .project:
            manager.addPage(to: folderID, in: notebookID, title: "Project Overview", content: "# Project Overview\n\n- [ ] Goals\n- [ ] Timeline\n- [ ] Stakeholders")
            manager.addPage(to: folderID, in: notebookID, title: "Milestones", content: "# Milestones\n\n1. Initial Design\n2. Prototype\n3. Final Release")
        case .meeting:
            manager.addPage(to: folderID, in: notebookID, title: "Agenda", content: "# Meeting Agenda\n\n- Topic 1\n- Topic 2")
            manager.addPage(to: folderID, in: notebookID, title: "Action Items", content: "# Action Items\n\n- [ ] Action 1")
        case .research:
            manager.addPage(to: folderID, in: notebookID, title: "Bibliography", content: "# Bibliography\n\n- Source 1")
            manager.addPage(to: folderID, in: notebookID, title: "Notes", content: "# Research Notes")
        case .planning:
            manager.addPage(to: folderID, in: notebookID, title: "Roadmap", content: "# Product Roadmap")
            manager.addPage(to: folderID, in: notebookID, title: "Requirements", content: "# Product Requirements Document")
        case .journal:
            manager.addPage(to: folderID, in: notebookID, title: "Daily Entry", content: "# Daily Journal\n\nDate: \(Date().formatted(date: .long, time: .omitted))\n\nHow am I feeling?\nWhat did I accomplish today?\nWhat am I grateful for?")
            manager.addPage(to: folderID, in: notebookID, title: "Weekly Reflection", content: "# Weekly Reflection\n\n- Wins of the week\n- Challenges\n- Goals for next week")
        case .recipes:
            manager.addPage(to: folderID, in: notebookID, title: "Dinner Ideas", content: "# Dinner Ideas\n\n- Pasta Carbonara\n- Grilled Salmon\n- Quinoa Salad")
            manager.addPage(to: folderID, in: notebookID, title: "Shopping List", content: "# Shopping List\n\n- [ ] Olive oil\n- [ ] Garlic\n- [ ] Basil")
        case .snippets:
            manager.addPage(to: folderID, in: notebookID, title: "Swift Helpers", content: "# Swift Snippets\n\n```swift\nextension UIView {\n    func addShadow() { ... }\n}\n```")
            manager.addPage(to: folderID, in: notebookID, title: "Shell Scripts", content: "# Useful Commands\n\n`find . -name \"*.swift\"`")
        case .course:
            manager.addPage(to: folderID, in: notebookID, title: "Syllabus", content: "# Course Syllabus\n\nInstructor:\nOffice Hours:\nGrading Scale:")
            manager.addPage(to: folderID, in: notebookID, title: "Lecture Notes", content: "# Lecture 1\n\nDate: \nSummary: \nKey Takeaways:")
        case .fitness:
            manager.addPage(to: folderID, in: notebookID, title: "Workout Plan", content: "# Weekly Workouts\n\n- Mon: Chest/Triceps\n- Wed: Back/Biceps\n- Fri: Legs/Shoulders")
            manager.addPage(to: folderID, in: notebookID, title: "Progress Tracker", content: "# Progress\n\n| Date | Weight | Notes |\n|------|--------|-------|\n| | | |")
        case .finance:
            manager.addPage(to: folderID, in: notebookID, title: "Monthly Budget", content: "# Budget\n\nIncome:\nFixed Expenses:\nSavings Goal:")
            manager.addPage(to: folderID, in: notebookID, title: "Subscription Tracker", content: "# Subscriptions\n\n- Netflix: $15.99\n- Spotify: $9.99")
        case .travel:
            manager.addPage(to: folderID, in: notebookID, title: "Itinerary", content: "# Trip Itinerary\n\nDay 1: Arrival & Check-in\nDay 2: Sightseeing\nDay 3: Relaxation")
            manager.addPage(to: folderID, in: notebookID, title: "Packing List", content: "# Packing Checklist\n\n- [ ] Passport\n- [ ] Chargers\n- [ ] Toiletries")
        case .inventory:
            manager.addPage(to: folderID, in: notebookID, title: "Home Inventory", content: "# Home Assets\n\n- Laptop: Serial #...\n- Camera: Model ...")
            manager.addPage(to: folderID, in: notebookID, title: "Storage Box Log", content: "# Storage Boxes\n\nBox A: Winter Clothes\nBox B: Holiday Decor")
        case .reading:
            manager.addPage(to: folderID, in: notebookID, title: "To Read", content: "# Reading List\n\n1. The Great Gatsby\n2. Sapiens\n3. Atomic Habits")
            manager.addPage(to: folderID, in: notebookID, title: "Book Notes", content: "# Book Review\n\nTitle:\nAuthor:\nRating:\nFavorite Quote:")
        case .dream:
            manager.addPage(to: folderID, in: notebookID, title: "Dream Log", content: "# Last Night's Dream\n\nDate: \nDescription: \nInterpretation: \nTags: ")
        case .client:
            manager.addPage(to: folderID, in: notebookID, title: "Client Contact Info", content: "# Client Directory\n\nName:\nEmail:\nCompany:")
            manager.addPage(to: folderID, in: notebookID, title: "Project Briefs", content: "# Active Projects\n\nProject A: Branding\nProject B: Website Redesign")
        case .brand:
            manager.addPage(to: folderID, in: notebookID, title: "Visual Style", content: "# Brand Identity\n\nColors:\nTypography:\nLogo Usage:")
            manager.addPage(to: folderID, in: notebookID, title: "Voice & Tone", content: "# Communication Guide\n\n- Friendly but professional\n- Direct and concise")
        case .lecture:
            manager.addPage(to: folderID, in: notebookID, title: "Lecture 1", content: "# Lecture Notes\n\nDate: \nTopic: \nKey Points:")
        case .wiki:
            manager.addPage(to: folderID, in: notebookID, title: "Home", content: "# Wiki Home\n\nWelcome to your personal wiki.")
        case .budget:
            manager.addPage(to: folderID, in: notebookID, title: "Monthly Overview", content: "# Budget\n\nIncome:\nExpenses:")
        case .trip:
            manager.addPage(to: folderID, in: notebookID, title: "Itinerary", content: "# Trip Itinerary")
        case .habit:
            manager.addPage(to: folderID, in: notebookID, title: "Habits", content: "# Habit Tracking")
        case .workout:
            manager.addPage(to: folderID, in: notebookID, title: "Workout", content: "# Daily Workout")
        case .contacts:
            manager.addPage(to: folderID, in: notebookID, title: "Contacts", content: "# Contact Directory")
        case .inventory2:
            manager.addPage(to: folderID, in: notebookID, title: "Home Assets", content: "# Inventory")
        case .ideas:
            manager.addPage(to: folderID, in: notebookID, title: "Idea List", content: "# Bank of Ideas")
        case .tasks:
            manager.addPage(to: folderID, in: notebookID, title: "Tasks", content: "# Task List\n\n- [ ] Task 1")
        }
    }
}
