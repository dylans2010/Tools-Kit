import SwiftUI
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

struct EditFormView: View {
    @ObservedObject var backend: FormsBackend
    @State var form: FormDocument
    @Environment(\.dismiss) private var dismiss

    @State private var showingFillOut = false
    @State private var showingAnswerImporter = false
    @State private var showingExport = false
    @State private var selectedType: FormQuestionType = .textInput
    @State private var expandedQuestionID: UUID?
    @State private var importPermissionError: String?

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
        Color(hex: form.accentHexColor)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Form Details card
                editCard {
                    VStack(alignment: .leading, spacing: 12) {
                        cardHeader("Form Details", icon: "info.circle")
                        editField("Name", text: $form.name)
                        editField("Description", text: $form.description)
                        editField("Creator", text: $form.manifest.createdBy)
                        editField("Privacy Note", text: $form.manifest.privacyNote)
                        editField("Tags", text: Binding(
                            get: { form.manifest.tags.joined(separator: ", ") },
                            set: { form.manifest.tags = splitOptions($0) }
                        ))
                    }
                }

                // Style card
                editCard {
                    VStack(alignment: .leading, spacing: 12) {
                        cardHeader("Style", icon: "paintpalette")
                        HStack(spacing: 12) {
                            editField("Accent Hex", text: $form.accentHexColor)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(accentColor)
                                .frame(width: 40, height: 36)
                        }
                    }
                }

                // Add question
                editCard {
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
                if !form.questions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("\(form.questions.count) Question\(form.questions.count == 1 ? "" : "s")", systemImage: "list.number")
                                .font(.subheadline.bold())
                            Spacer()
                            EditButton()
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 4)

                        ForEach($form.questions) { $question in
                            questionCard(binding: $question)
                        }
                        .onDelete { form.questions.remove(atOffsets: $0) }
                        .onMove { form.questions.move(fromOffsets: $0, toOffset: $1) }
                    }
                }

                // Actions card
                editCard {
                    VStack(spacing: 10) {
                        cardHeader("Actions", icon: "bolt.circle")

                        actionRow(title: "Save Changes", icon: "checkmark.circle.fill", color: .green) {
                            saveChanges()
                        }
                        Divider()
                        actionRow(title: "Fill Out Form", icon: "pencil.and.list.clipboard", color: accentColor) {
                            showingFillOut = true
                        }
                        Divider()
                        actionRow(title: "Export .form", icon: "square.and.arrow.up", color: .orange) {
                            showingExport = true
                        }
                        Divider()
                        actionRow(title: "Import Filled Answers", icon: "tray.and.arrow.down", color: .purple) {
                            guard backend.isOwner(of: form) else {
                                importPermissionError = "Only the form owner can import and review submitted answers."
                                return
                            }
                            showingAnswerImporter = true
                        }
                    }
                }

                // Reviewed answers
                if let reviewed = backend.reviewedAnswers, reviewed.formID == form.id, backend.isOwner(of: form) {
                    editCard {
                        VStack(alignment: .leading, spacing: 10) {
                            cardHeader("Reviewed Answers", icon: "checkmark.seal")
                            Text("Responder: \(reviewed.responderName)")
                                .font(.subheadline)
                            ForEach(form.questions) { question in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(question.title)
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary)
                                    Text(reviewed.answers[question.id] ?? "No Answer")
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 4)
                                Divider()
                            }
                        }
                    }
                }

                // Manifest info
                editCard {
                    VStack(alignment: .leading, spacing: 8) {
                        cardHeader("Manifest", icon: "doc.badge.gearshape")
                        ManifestDataForm(manifest: form.manifest)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Edit Form")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingFillOut) {
            NavigationStack { FillOutFormView(form: form, backend: backend) }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingExport) {
            ExportFormView(form: form)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAnswerImporter) {
            FileImporterRepresentableView(allowedContentTypes: [UTType(filenameExtension: "form") ?? .data]) { urls in
                guard let url = urls.first else { return }
                if let answers = try? FilledOutFormManager.importAnswers(from: url),
                   FilledOutFormManager.canReviewAnswers(answers, for: form) {
                    backend.reviewedAnswers = answers
                } else {
                    importPermissionError = "This answers file does not match this form or you do not have permission to review it."
                }
            }
        }
        .alert("Import Error", isPresented: Binding(
            get: { importPermissionError != nil },
            set: { if !$0 { importPermissionError = nil } }
        )) {
            Button("OK", role: .cancel) { importPermissionError = nil }
        } message: {
            Text(importPermissionError ?? "")
        }
    }

    // MARK: - Question Card

    @ViewBuilder
    private func questionCard(binding: Binding<FormQuestion>) -> some View {
        let question = binding.wrappedValue
        let isExpanded = expandedQuestionID == question.id

        VStack(alignment: .leading, spacing: 0) {
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

    private func editCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
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

    private func editField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(label, text: text)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
        }
    }

    private func actionRow(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 22)
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func addQuestion() {
        if let manager = managers.first(where: { $0.type == selectedType }) {
            let newQuestion = manager.defaultQuestion()
            form.questions.append(newQuestion)
            expandedQuestionID = newQuestion.id
        }
    }

    private func saveChanges() {
        form.manifest.lastEditedAt = Date()
        form.manifest.questionCount = form.questions.count
        form.manifest.requiredQuestionCount = form.questions.filter(\.required).count
        form.manifest.supportsAttachments = form.questions.contains(where: { $0.type == .imageUpload })
        backend.update(form)
    }

    private func splitOptions(_ value: String) -> [String] {
        value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
