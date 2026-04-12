import Foundation

@MainActor
final class FormsBackend: ObservableObject {
    @Published var forms: [FormDocument] = []
    @Published var importedForm: FormDocument?
    @Published var reviewedAnswers: FilledOutFormDocument?
    @Published private(set) var ownedFormIDs: Set<UUID> = []

    private let saveURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("forms-library.json")
    private let ownershipURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("forms-ownership.json")
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

    func add(_ form: FormDocument, isOwned: Bool = true) {
        let normalizedForm = normalized(form)
        forms.insert(normalizedForm, at: 0)
        if isOwned {
            ownedFormIDs.insert(normalizedForm.id)
        } else {
            ownedFormIDs.remove(normalizedForm.id)
        }
        save()
    }

    func update(_ form: FormDocument) {
        guard let index = forms.firstIndex(where: { $0.id == form.id }) else { return }
        forms[index] = normalized(form)
        save()
    }

    func remove(_ form: FormDocument) {
        forms.removeAll { $0.id == form.id }
        ownedFormIDs.remove(form.id)
        save()
    }

    func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([FormDocument].self, from: data) else { return }
        forms = decoded
        loadOwnership()
    }

    func save() {
        guard let data = try? JSONEncoder().encode(forms) else { return }
        try? data.write(to: saveURL)

        guard let ownershipData = try? JSONEncoder().encode(Array(ownedFormIDs)) else { return }
        try? ownershipData.write(to: ownershipURL)
    }

    func isOwner(of form: FormDocument) -> Bool {
        ownedFormIDs.contains(form.id)
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

    private func loadOwnership() {
        guard let data = try? Data(contentsOf: ownershipURL),
              let decoded = try? JSONDecoder().decode([UUID].self, from: data) else {
            ownedFormIDs = Set(forms.map(\.id))
            return
        }
        ownedFormIDs = Set(decoded)
    }
}
