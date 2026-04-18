import SwiftUI

struct CreateFormView: View {
    @ObservedObject var backend: FormsBackend
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var questions: [FormQuestion] = []
    @State private var selectedType: FormQuestionType = .textInput
    @State private var accentHex = "007AFF"
    @State private var backgroundHex = "F2F2F7"
    @State private var cardCornerRadius: Double = 14
    @State private var cardShadowOpacity: Double = 0.05
    @State private var creatorName = ""
    @State private var privacyNote = "Review the Manifest before sharing."
    @State private var tags = ""
    @State private var expandedQuestionID: UUID?
    @State private var aiPrompt = ""
    @State private var aiLoading = false
    @State private var aiError: String?

    private let managers: [FormOptionManager] = [
        TextInputOptionManager(),
        MultipleChoiceOptionManager(),
        RatingScaleOptionManager(),
        SliderOptionManager(),
        DropdownOptionManager(),
        ImageUploadOptionManager(),
        DragDropOptionManager()
    ]

    private var accentColor: Color {
        Color(hex: accentHex) ?? .blue
    }

    private var backgroundColor: Color {
        Color(hex: backgroundHex) ?? Color(.secondarySystemGroupedBackground)
    }

    private var attachStatusText: String {
        questions.contains(where: { $0.type == .imageUpload }) ? "Yes" : "No"
    }

    private var attachChipText: String {
        "Attach \(attachStatusText)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                formCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Create Smart Form")
                                    .font(.title2.bold())
                                Text("Design production-ready forms with better UX, metadata, and AI-assisted drafting.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Label("\(questions.count) Q", systemImage: "list.number")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(accentColor.opacity(0.14))
                                .clipShape(Capsule())
                        }
                        HStack(spacing: 8) {
                            statusChip("Required \(questions.filter(\.required).count)", icon: "asterisk.circle", color: .red)
                            statusChip(attachChipText, icon: "paperclip", color: .purple)
                            statusChip("Manifest Ready", icon: "checkmark.shield", color: .green)
                        }
                    }
                }

                // Basics
                formCard {
                    VStack(alignment: .leading, spacing: 12) {
                        cardHeader("Form Details", icon: "info.circle")
                        formField("Form Name", placeholder: "My Survey", text: $name)
                        formField("Description", placeholder: "What is this form about?", text: $description)
                        formField("Creator Name", placeholder: "Your Name", text: $creatorName)
                    }
                }

                // Style
                formCard {
                    VStack(alignment: .leading, spacing: 12) {
                        cardHeader("Style", icon: "paintpalette")
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Accent")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("007AFF", text: $accentHex)
                                    .textFieldStyle(.roundedBorder)
                                    .autocapitalization(.allCharacters)
                                ColorPicker("Accent Color", selection: Binding(
                                    get: { accentColor },
                                    set: { if let hex = $0.toHex() { accentHex = hex } }
                                ), supportsOpacity: false)
                                    .font(.caption)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Background")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("F2F2F7", text: $backgroundHex)
                                    .textFieldStyle(.roundedBorder)
                                    .autocapitalization(.allCharacters)
                                ColorPicker("Background Color", selection: Binding(
                                    get: { backgroundColor },
                                    set: { if let hex = $0.toHex() { backgroundHex = hex } }
                                ), supportsOpacity: false)
                                    .font(.caption)
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Card Roundness")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(value: $cardCornerRadius, in: 10...24, step: 1)
                            Text("\(Int(cardCornerRadius)) px")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Shadow")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(value: $cardShadowOpacity, in: 0...0.15, step: 0.01)
                            Text("\(Int(cardShadowOpacity * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        RoundedRectangle(cornerRadius: CGFloat(cardCornerRadius))
                            .fill(backgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: CGFloat(cardCornerRadius))
                                    .stroke(accentColor.opacity(0.25), lineWidth: 1)
                            )
                            .frame(height: 60)
                            .overlay(
                                HStack {
                                    Circle().fill(accentColor).frame(width: 16, height: 16)
                                    Text("Live Style Preview")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                            )
                    }
                }

                formCard {
                    VStack(alignment: .leading, spacing: 12) {
                        cardHeader("AI Question Builder", icon: "sparkles")
                        TextField("e.g. Build a customer onboarding quality survey", text: $aiPrompt, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        if aiLoading {
                            ProgressView("Generating questions…")
                                .font(.caption)
                        } else if let aiError {
                            Text(aiError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        HStack {
                            Button("Generate Questions", action: generateAIQuestions)
                                .buttonStyle(.borderedProminent)
                                .disabled(aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiLoading)
                            Spacer()
                            Button("Template: Feedback") {
                                aiPrompt = "Create 6 customer feedback questions with one rating, one dropdown, and one text follow-up."
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                // Add question
                formCard {
                    VStack(alignment: .leading, spacing: 12) {
                        cardHeader("Add Question", icon: "plus.circle")

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(FormQuestionType.allCases) { type in
                                    typeChip(type: type)
                                }
                            }
                        }

                        Button {
                            addQuestion()
                        } label: {
                            Label("Add \(selectedType.displayName)", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Questions
                if !questions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("\(questions.count) Question\(questions.count == 1 ? "" : "s")", systemImage: "list.number")
                                .font(.subheadline.bold())
                            Spacer()
                            EditButton()
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 4)

                        ForEach(Array(questions.indices), id: \.self) { index in
                            questionCard(binding: $questions[index], index: index + 1)
                        }
                        .onDelete { questions.remove(atOffsets: $0) }
                        .onMove { questions.move(fromOffsets: $0, toOffset: $1) }
                    }
                }

                // Manifest / advanced
                formCard {
                    VStack(alignment: .leading, spacing: 12) {
                        cardHeader("Manifest", icon: "doc.badge.gearshape")
                        formField("Privacy Note", placeholder: "Review before sharing", text: $privacyNote)
                        formField("Tags", placeholder: "tag1, tag2, tag3", text: $tags)
                    }
                }

                // Create button
                Button {
                    createForm()
                } label: {
                    Label("Create Form", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .font(.headline)
                }
                .buttonStyle(.plain)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            }
            .padding()
        }
        .background(backgroundColor.opacity(0.35).ignoresSafeArea())
        .navigationTitle("Create Form")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    // MARK: - Question Card

    @ViewBuilder
    private func questionCard(binding: Binding<FormQuestion>, index: Int) -> some View {
        let question = binding.wrappedValue
        let isExpanded = expandedQuestionID == question.id

        VStack(alignment: .leading, spacing: 0) {
            // Row header
            Button {
                withAnimation(.spring(response: 0.3)) {
                    expandedQuestionID = isExpanded ? nil : question.id
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: question.type.icon)
                        .foregroundColor(accentColor)
                        .frame(width: 22)

                    Text("\(index)")
                        .font(.caption.bold())
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accentColor.opacity(0.12))
                        .clipShape(Capsule())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(question.title.isEmpty ? "Untitled Question" : question.title)
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        Text(question.type.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if question.required {
                        Text("Required")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.12))
                            .foregroundColor(.red)
                            .cornerRadius(4)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                QuestionEditorView(question: binding)
                    .padding(14)
            }
        }
        .background(Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: CGFloat(cardCornerRadius))
                .stroke(accentColor.opacity(0.14), lineWidth: 1)
        )
        .cornerRadius(CGFloat(cardCornerRadius))
    }

    // MARK: - Type Chip

    private func typeChip(type: FormQuestionType) -> some View {
        Button {
            selectedType = type
        } label: {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.caption)
                Text(type.displayName)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selectedType == type ? accentColor : Color(.tertiarySystemBackground))
            .foregroundColor(selectedType == type ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func formCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
                .padding(16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(CGFloat(cardCornerRadius))
        .shadow(color: .black.opacity(cardShadowOpacity), radius: 8, y: 4)
    }

    private func cardHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.bold())
            .foregroundColor(.secondary)
    }

    private func formField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(placeholder, text: text)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
        }
    }

    private func statusChip(_ text: String, icon: String, color: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .clipShape(Capsule())
    }

    private func addQuestion() {
        if let manager = managers.first(where: { $0.type == selectedType }) {
            let newQuestion = manager.defaultQuestion()
            questions.append(newQuestion)
            expandedQuestionID = newQuestion.id
        }
    }

    private func createForm() {
        let tagList = tags.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let form = FormDocument(
            name: name.isEmpty ? "Untitled Form" : name,
            description: description,
            questions: questions,
            accentHexColor: accentHex,
            backgroundHexColor: backgroundHex,
            manifest: FormManifest.compose(
                creatorName: creatorName,
                questions: questions,
                privacyNote: privacyNote,
                tags: tagList
            )
        )
        backend.add(form)
        dismiss()
    }

    private func generateAIQuestions() {
        let prompt = aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        aiLoading = true
        aiError = nil
        Task {
            do {
                let output = try await AIService.shared.processText(
                    prompt: """
                    Create a concise list of form questions from this request:
                    \(prompt)

                    Return only plain text bullets, one question per line.
                    """,
                    systemPrompt: "You are a form UX designer. Keep questions specific and practical."
                )
                let generated = output
                    .split(separator: "\n")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .map { $0.replacingOccurrences(of: "^-\\s*", with: "", options: .regularExpression) }
                    .map { $0.replacingOccurrences(of: "^\\d+[.)]\\s*", with: "", options: .regularExpression) }
                    .filter { !$0.isEmpty }
                    .prefix(8)
                await MainActor.run {
                    for title in generated where !questions.contains(where: { $0.title.caseInsensitiveCompare(title) == .orderedSame }) {
                        questions.append(FormQuestion(title: title, type: .textInput, required: false))
                    }
                    if let last = questions.last { expandedQuestionID = last.id }
                    aiLoading = false
                }
            } catch {
                await MainActor.run {
                    aiError = "Could not generate questions right now. Try a more specific request."
                    aiLoading = false
                }
            }
        }
    }
}
