import SwiftUI
import UniformTypeIdentifiers

/// Shows a summary / metadata overview for a single FormDocument.
struct FormDetailView: View {
    let form: FormDocument
    @ObservedObject var backend: FormsBackend

    @State private var showFillOut = false
    @State private var showEdit = false
    @State private var showExport = false
    @State private var showAnswerImporter = false
    @State private var importError: String?

    private var accentColor: Color {
        Color(hex: form.accentHexColor) ?? .blue
    }

    private var backgroundColor: Color {
        Color(hex: form.backgroundHexColor) ?? Color(.secondarySystemGroupedBackground)
    }

    private var canReviewAnswers: Bool {
        backend.isOwner(of: form)
    }

    private var reviewedAnswers: FilledOutFormDocument? {
        guard let reviewed = backend.reviewedAnswers, reviewed.formID == form.id else { return nil }
        return reviewed
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                headerCard

                actionGrid

                if !canReviewAnswers {
                    permissionCard
                }

                questionsSection

                if let reviewedAnswers, canReviewAnswers {
                    reviewedAnswersSection(reviewedAnswers)
                }

                manifestSection
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(backgroundColor.opacity(0.35).ignoresSafeArea())
        .navigationTitle("Form Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFillOut) {
            NavigationStack { FillOutFormView(form: form, backend: backend) }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEdit) {
            NavigationStack { EditFormView(backend: backend, form: form) }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showExport) {
            ExportFormView(form: form)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAnswerImporter) {
            FileImporterRepresentableView(allowedContentTypes: [UTType(filenameExtension: "form") ?? .data]) { urls in
                guard let url = urls.first else { return }
                importAnswers(from: url)
            }
        }
        .alert("Import Error", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK", role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "")
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(form.name)
                        .font(.title2.bold())
                    if !form.description.isEmpty {
                        Text(form.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "list.bullet.rectangle.portrait.fill")
                    .font(.title)
                    .foregroundStyle(accentColor)
            }

            HStack(spacing: 10) {
                statPill(icon: "questionmark.circle", label: "Questions", value: "\(form.questions.count)")
                statPill(icon: "asterisk.circle", label: "Required", value: "\(form.questions.filter(\.required).count)")
                statPill(icon: "person.crop.circle", label: "Owner", value: canReviewAnswers ? "You" : "Shared")
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), accentColor.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var actionGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            actionButton(title: "Fill Out", icon: "pencil.and.list.clipboard", color: accentColor) {
                showFillOut = true
            }
            actionButton(title: "Edit", icon: "square.and.pencil", color: .orange) {
                showEdit = true
            }
            actionButton(title: "Export", icon: "square.and.arrow.up", color: .green) {
                showExport = true
            }
            actionButton(title: "Import Answers", icon: "tray.and.arrow.down", color: .purple) {
                guard canReviewAnswers else {
                    importError = "Only the form owner can import and review submitted answers."
                    return
                }
                showAnswerImporter = true
            }
        }
    }

    private var permissionCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.shield")
                .foregroundColor(.secondary)
            Text("This is a shared form. Only the original owner can import and review submitted answers.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Questions", subtitle: "\(form.questions.count)", icon: "list.number")
            VStack(spacing: 8) {
                ForEach(Array(form.questions.enumerated()), id: \.element.id) { index, question in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .foregroundColor(accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(accentColor.opacity(0.12))
                            .clipShape(Capsule())

                        Image(systemName: question.type.icon)
                            .foregroundColor(accentColor)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(question.title.isEmpty ? "Untitled" : question.title)
                                .font(.subheadline.weight(.semibold))
                            Text(question.type.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if question.required {
                            Text("Required")
                                .font(.caption2)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.red.opacity(0.12))
                                .foregroundColor(.red)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private func reviewedAnswersSection(_ reviewed: FilledOutFormDocument) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Imported Answers", subtitle: reviewed.responderName, icon: "checkmark.seal")

            ForEach(form.questions) { question in
                VStack(alignment: .leading, spacing: 4) {
                    Text(question.title.isEmpty ? question.type.displayName : question.title)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    Text(reviewed.answers[question.id] ?? "No Answer")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var manifestSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Manifest", subtitle: nil, icon: "doc.badge.gearshape")
            ManifestDataForm(manifest: form.manifest)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func statPill(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.caption2)
            .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            .padding(12)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func importAnswers(from url: URL) {
        guard canReviewAnswers else {
            importError = "Only the form owner can import and review submitted answers."
            return
        }

        do {
            let importedAnswers = try FilledOutFormManager.importAnswers(from: url)
            guard FilledOutFormManager.canReviewAnswers(importedAnswers, for: form) else {
                importError = "This answers file does not match this form or you do not have permission to review it."
                return
            }
            backend.reviewedAnswers = importedAnswers
        } catch {
            importError = "Could not import answers: \(error.localizedDescription)"
        }
    }
}
