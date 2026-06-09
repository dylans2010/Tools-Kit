import SwiftUI

public struct ReporterFeedbackView: View {
    @StateObject private var viewModel: ReporterFeedbackViewModel
    @Environment(\.dismiss) private var dismiss

    public init(category: FeedbackCategory? = nil) {
        _viewModel = StateObject(wrappedValue: ReporterFeedbackViewModel(initialCategory: category))
    }

    public var body: some View {
        VStack {
            progressHeader

            ScrollView {
                VStack(spacing: 20) {
                    switch viewModel.currentStep {
                    case 1: stepContextSelection
                    case 2: stepDynamicQuestions
                    case 3: stepSmartAttachments
                    case 4: stepDiagnosticsCapture
                    case 5: stepAIAnalysis
                    case 6: stepReviewSubmit
                    default: EmptyView()
                    }
                }
                .padding()
            }

            Spacer()

            navigationFooter
        }
        .navigationTitle("New Report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save Draft") {
                    viewModel.saveDraft()
                    dismiss()
                }
            }
        }
        .alert("Report Submitted", isPresented: $viewModel.isComplete) {
            Button("OK") { dismiss() }
        } message: {
            Text("Thank you for your feedback! We've received your report and will review it soon.")
        }
    }

    private var progressHeader: some View {
        HStack(spacing: 4) {
            ForEach(1...6, id: \.self) { step in
                Rectangle()
                    .fill(step <= viewModel.currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal)
    }

    private var navigationFooter: some View {
        HStack {
            if viewModel.currentStep > 1 {
                Button("Back") {
                    viewModel.prevStep()
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if viewModel.currentStep < 6 {
                Button("Next") {
                    viewModel.nextStep()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(action: { viewModel.submit() }) {
                    if viewModel.isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Submit Report")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isSubmitting)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Steps

    private var stepContextSelection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("What's this about?")
                .font(.title2.bold())

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(FeedbackCategory.allCases) { category in
                    Button {
                        viewModel.updateCategory(category)
                    } label: {
                        VStack {
                            Image(systemName: category.icon)
                                .font(.largeTitle)
                            Text(category.displayName)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.report.category == category ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.report.category == category ? Color.blue : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var stepDynamicQuestions: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Tell us more")
                .font(.title2.bold())

            VStack(alignment: .leading) {
                Text("Summary")
                    .font(.headline)
                TextField("Quick overview of the issue", text: $viewModel.report.summary)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading) {
                Text("Details")
                    .font(.headline)
                TextEditor(text: $viewModel.report.description)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            }

            VStack(alignment: .leading) {
                Text("Reproduction Steps")
                    .font(.headline)
                Text("List them line by line")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextEditor(text: Binding(
                    get: { viewModel.report.reproductionSteps.joined(separator: "\n") },
                    set: { viewModel.report.reproductionSteps = $0.components(separatedBy: .newlines).filter { !$0.isEmpty } }
                ))
                .frame(height: 80)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            }

            VStack(alignment: .leading) {
                Text("Severity / Impact")
                    .font(.headline)
                HStack {
                    Slider(value: Binding(
                        get: { Double(viewModel.report.impactScore) },
                        set: { viewModel.report.impactScore = Int($0) }
                    ), in: 1...10, step: 1)
                    Text("\(viewModel.report.impactScore)")
                        .bold()
                        .frame(width: 30)
                }
            }

            Divider()

            ForEach(viewModel.report.category.questions) { question in
                dynamicQuestionRow(question)
            }
        }
    }

    private func dynamicQuestionRow(_ question: FeedbackQuestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(question.title)
                    .font(.headline)
                if question.isRequired {
                    Text("*")
                        .foregroundColor(.red)
                }
            }

            switch question.type {
            case .text:
                TextField(question.placeholder ?? "", text: dynamicBinding(for: question.id))
                    .textFieldStyle(.roundedBorder)
            case .longText:
                TextEditor(text: dynamicBinding(for: question.id))
                    .frame(height: 80)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            case .toggle:
                Toggle("", isOn: Binding(
                    get: { (viewModel.report.dynamicAnswers[question.id] ?? "false") == "true" },
                    set: { viewModel.report.dynamicAnswers[question.id] = $0 ? "true" : "false" }
                ))
                .labelsHidden()
            case .singleChoice:
                Picker("", selection: dynamicBinding(for: question.id)) {
                    Text("Select one").tag("")
                    ForEach(question.options ?? [], id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private func dynamicBinding(for id: String) -> Binding<String> {
        Binding(
            get: { viewModel.report.dynamicAnswers[id] ?? "" },
            set: { viewModel.report.dynamicAnswers[id] = $0 }
        )
    }

    private var stepSmartAttachments: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Attachments")
                .font(.title2.bold())

            Text("Add images, screen recordings, or logs to help us understand.")
                .foregroundColor(.secondary)

            HStack(spacing: 15) {
                AttachmentButton(icon: "photo", label: "Image") {
                    addMockAttachment(name: "screenshot.png", type: .image)
                }
                AttachmentButton(icon: "record.circle", label: "Recording") {
                    addMockAttachment(name: "screen_recording.mov", type: .video)
                }
                AttachmentButton(icon: "doc", label: "File") {
                    addMockAttachment(name: "diagnostic_log.txt", type: .file)
                }
            }

            if !viewModel.report.attachments.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.report.attachments) { attachment in
                        HStack {
                            Image(systemName: attachment.type == .image ? "photo" : attachment.type == .video ? "video" : "doc")
                            Text(attachment.name)
                                .font(.subheadline)
                            Spacer()
                            Button {
                                viewModel.report.attachments.removeAll(where: { $0.id == attachment.id })
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }

    private func addMockAttachment(name: String, type: FeedbackAttachment.AttachmentType) {
        let newAttachment = FeedbackAttachment(
            id: UUID(),
            name: name,
            type: type,
            url: nil,
            localPath: "/mock/path/\(name)"
        )
        viewModel.report.attachments.append(newAttachment)
    }

    private var stepDiagnosticsCapture: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Diagnostics")
                .font(.title2.bold())

            Toggle("Provide Logs & Diagnostics", isOn: $viewModel.provideDiagnostics)
                .font(.headline)

            Text("This includes app logs, device info, and system performance snapshots. It helps us debug issues much faster.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if viewModel.provideDiagnostics {
                if let diagnostics = viewModel.capturedDiagnostics {
                    VStack(alignment: .leading, spacing: 8) {
                        DiagnosticRow(label: "Device", value: diagnostics.deviceName)
                        DiagnosticRow(label: "OS", value: diagnostics.osVersion)
                        DiagnosticRow(label: "App", value: "\(diagnostics.appVersion) (\(diagnostics.buildNumber))")
                        DiagnosticRow(label: "Memory", value: diagnostics.memoryUsage)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                } else {
                    HStack {
                        ProgressView()
                        Text("Capturing diagnostics...")
                    }
                }
            }
        }
    }

    private var stepAIAnalysis: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("AI Pre-Analysis")
                .font(.title2.bold())

            if viewModel.isAnalyzing {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Analyzing your report...")
                        .font(.headline)
                    Text("We're detecting duplicates and identifying potential root causes.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if let analysis = viewModel.report.aiAnalysis {
                VStack(alignment: .leading, spacing: 15) {
                    Label("Analysis Complete", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundColor(.purple)

                    Text(analysis.summary)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Suggested Priority: \(analysis.suggestedPriority.displayName)")
                            .bold()
                        Text("Likely Cause: \(analysis.rootCauseHypothesis)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    FlowLayout(analysis.suggestedTags, spacing: 8) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(20)
                    }
                }
            }
        }
    }

    private var stepReviewSubmit: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Review & Submit")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.report.summary)
                    .font(.headline)

                Text(viewModel.report.description)
                    .font(.body)

                Divider()

                HStack {
                    Label(viewModel.report.category.displayName, systemImage: viewModel.report.category.icon)
                    Spacer()
                    Text(viewModel.report.priority.displayName)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(viewModel.report.priority.color.opacity(0.2))
                        .foregroundColor(viewModel.report.priority.color)
                        .cornerRadius(4)
                }
                .font(.caption)

                if !viewModel.report.dynamicAnswers.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(viewModel.report.category.questions) { question in
                            if let answer = viewModel.report.dynamicAnswers[question.id], !answer.isEmpty {
                                HStack {
                                    Text(question.title + ":").bold()
                                    Text(answer)
                                }
                                .font(.caption)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

private struct AttachmentButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.title)
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

private struct DiagnosticRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).bold()
        }
        .font(.caption)
    }
}

