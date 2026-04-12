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
    @State private var creatorName = ""
    @State private var privacyNote = "Review manifest before sharing."
    @State private var tags = ""
    @State private var expandedQuestionID: UUID?

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

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Basics
                formCard {
                    VStack(alignment: .leading, spacing: 12) {
                        cardHeader("Form Details", icon: "info.circle")
                        formField("Form Name", placeholder: "My Survey", text: $name)
                        formField("Description", placeholder: "What is this form about?", text: $description)
                        formField("Creator Name", placeholder: "Your name", text: $creatorName)
                    }
                }

                // Style
                formCard {
                    VStack(alignment: .leading, spacing: 12) {
                        cardHeader("Style", icon: "paintpalette")
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Accent Color").font(.caption).foregroundColor(.secondary)
                                TextField("Hex e.g. 007AFF", text: $accentHex)
                                    .textFieldStyle(.roundedBorder)
                                    .autocapitalization(.allCharacters)
                            }
                            RoundedRectangle(cornerRadius: 8)
                                .fill(accentColor)
                                .frame(width: 40, height: 36)
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

                        ForEach($questions) { $question in
                            questionCard(binding: $question)
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
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Create Form")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    // MARK: - Question Card

    @ViewBuilder
    private func questionCard(binding: Binding<FormQuestion>) -> some View {
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
        .cornerRadius(12)
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
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
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
}

