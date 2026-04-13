import SwiftUI

struct FillOutFormView: View {
    let form: FormDocument
    @ObservedObject var backend: FormsBackend
    @Environment(\.dismiss) private var dismiss

    @State private var answers: [UUID: String] = [:]
    @State private var responderName = ""
    @State private var exportURL: URL?
    @State private var showValidationAlert = false
    @State private var showCompletedSheet = false

    private var accentColor: Color {
        Color(hex: form.accentHexColor) ?? .blue
    }

    private var unansweredRequired: [FormQuestion] {
        form.questions.filter { q in
            q.required && (answers[q.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Responder card
                VStack(alignment: .leading, spacing: 10) {
                    Label("Your Name", systemImage: "person.circle")
                        .font(.subheadline.bold())
                        .foregroundColor(accentColor)
                    TextField("Enter Your Name", text: $responderName)
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)

                // Questions
                ForEach(Array(form.questions.enumerated()), id: \.element.id) { index, question in
                    questionCard(question: question, index: index)
                }

                Button {
                    submitForm()
                } label: {
                    Label("Submit & Export Answers", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(form.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .alert("Required Questions Missing", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please answer all required questions before submitting.")
        }
        .sheet(isPresented: $showCompletedSheet) {
            completionSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func questionCard(question: FormQuestion, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: question.type.icon)
                    .foregroundColor(accentColor)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(question.title.isEmpty ? "Question \(index + 1)" : question.title)
                            .font(.subheadline.bold())
                        if question.required {
                            Text("*")
                                .foregroundColor(.red)
                                .font(.subheadline.bold())
                        }
                    }
                    if !question.questionName.isEmpty {
                        Text(question.questionName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Text(question.type.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(accentColor.opacity(0.1))
                    .foregroundColor(accentColor)
                    .cornerRadius(4)
            }

            // Interactive component
            FormQuestionRenderer(
                question: question,
                answer: Binding(
                    get: { answers[question.id] ?? "" },
                    set: { answers[question.id] = $0 }
                )
            )
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private func submitForm() {
        guard unansweredRequired.isEmpty else {
            showValidationAlert = true
            return
        }
        let doc = FilledOutFormDocument(
            formID: form.id,
            formName: form.name,
            answeredAt: Date(),
            answers: answers,
            responderName: responderName.isEmpty ? "Anonymous" : responderName,
            ownerAccessKey: form.ownerAccessKey
        )
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(form.name)-answers.form")
        try? FilledOutFormManager.exportAnswers(doc, to: url)
        exportURL = url
        showCompletedSheet = true
    }

    private var completionSheet: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 42, height: 5)
                .padding(.top, 4)

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundColor(accentColor)

            Text("Form Completed!")
                .font(.title3.bold())

            Text("Your responses were saved. Export the filled form to share it with the form owner.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            if let exportURL {
                ShareLink(item: exportURL) {
                    Label("Export Filled Form", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }

            Button("Done") {
                showCompletedSheet = false
            }
            .font(.subheadline.weight(.semibold))
            .padding(.top, 2)

            Spacer(minLength: 0)
        }
        .padding()
    }
}
