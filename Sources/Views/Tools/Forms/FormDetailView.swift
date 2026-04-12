import SwiftUI

/// Shows a summary / metadata overview for a single FormDocument.
struct FormDetailView: View {
    let form: FormDocument
    @ObservedObject var backend: FormsBackend

    @State private var showFillOut = false
    @State private var showEdit = false
    @State private var showExport = false

    private var accentColor: Color {
        Color(hex: form.accentHexColor) ?? .blue
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero card
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.rectangle.portrait")
                        .font(.system(size: 48))
                        .foregroundColor(accentColor)
                        .padding(.top, 8)

                    Text(form.name)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    if !form.description.isEmpty {
                        Text(form.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    HStack(spacing: 20) {
                        statBadge(label: "Questions", value: "\(form.questions.count)", icon: "questionmark.circle")
                        statBadge(label: "Required", value: "\(form.questions.filter(\.required).count)", icon: "exclamationmark.circle")
                    }
                    .padding(.top, 4)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)

                // Action buttons
                HStack(spacing: 12) {
                    actionButton(title: "Fill Out", icon: "pencil.and.list.clipboard", color: accentColor) {
                        showFillOut = true
                    }
                    actionButton(title: "Edit", icon: "square.and.pencil", color: .orange) {
                        showEdit = true
                    }
                    actionButton(title: "Export", icon: "square.and.arrow.up", color: .green) {
                        showExport = true
                    }
                }
                .padding(.horizontal)

                // Questions preview
                if !form.questions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Questions", subtitle: "\(form.questions.count)", icon: "list.number")
                            .padding(.horizontal)

                        VStack(spacing: 8) {
                            ForEach(Array(form.questions.enumerated()), id: \.element.id) { index, question in
                                HStack(spacing: 14) {
                                    Text("\(index + 1)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundColor(.secondary)
                                        .frame(width: 20, alignment: .center)

                                    Image(systemName: question.type.icon)
                                        .foregroundColor(accentColor)
                                        .frame(width: 22)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(question.title.isEmpty ? "Untitled" : question.title)
                                            .font(.subheadline)
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
                                            .background(Color.red.opacity(0.15))
                                            .foregroundColor(.red)
                                            .cornerRadius(4)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                        }
                    }
                }

                // Manifest card
                VStack(alignment: .leading, spacing: 0) {
                    SectionHeader(title: "Manifest", subtitle: nil, icon: "doc.badge.gearshape")
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    ManifestDataForm(manifest: form.manifest)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Form Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFillOut) {
            NavigationStack { FillOutFormView(form: form, backend: backend) }
        }
        .sheet(isPresented: $showEdit) {
            NavigationStack { EditFormView(backend: backend, form: form) }
        }
        .sheet(isPresented: $showExport) {
            ExportFormView(form: form)
        }
    }

    private func statBadge(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(accentColor)
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
