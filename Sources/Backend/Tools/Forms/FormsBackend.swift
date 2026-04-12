import Foundation

@MainActor
final class FormsBackend: ObservableObject {
    @Published var forms: [FormDocument] = []
    @Published var importedForm: FormDocument?
    @Published var reviewedAnswers: FilledOutFormDocument?

    private let saveURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("forms-library.json")
    private let managers: [FormOptionManager] = [
        TextInputOptionManager(),
        MultipleChoiceOptionManager(),
        RatingScaleOptionManager(),
        SliderOptionManager(),
        DropdownOptionManager(),
        ImageUploadOptionManager(),
        DragDropOptionManager()
    ]

    init() {
        load()
    }

    func add(_ form: FormDocument) {
        forms.insert(normalized(form), at: 0)
        save()
    }

    func update(_ form: FormDocument) {
        guard let index = forms.firstIndex(where: { $0.id == form.id }) else { return }
        forms[index] = normalized(form)
        save()
    }

    func remove(_ form: FormDocument) {
        forms.removeAll { $0.id == form.id }
        save()
    }

    func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([FormDocument].self, from: data) else { return }
        forms = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(forms) else { return }
        try? data.write(to: saveURL)
    }

    private func normalized(_ form: FormDocument) -> FormDocument {
        var updated = form
        updated.questions = form.questions.map { question in
            guard let manager = managers.first(where: { $0.type == question.type }) else { return question }
            var normalized = manager.normalize(question)
            if normalized.title.isEmpty {
                normalized.title = manager.defaultQuestion().title
            }
            return normalized
        }
        updated.manifest.lastEditedAt = Date()
        updated.manifest.questionCount = updated.questions.count
        updated.manifest.requiredQuestionCount = updated.questions.filter(\.required).count
        updated.manifest.supportsAttachments = updated.questions.contains(where: { $0.type == .imageUpload })
        return updated
    }
}
