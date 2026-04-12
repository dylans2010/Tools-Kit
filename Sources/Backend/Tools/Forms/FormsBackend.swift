import Foundation

@MainActor
final class FormsBackend: ObservableObject {
    @Published var forms: [FormDocument] = []
    @Published var importedForm: FormDocument?
    @Published var reviewedAnswers: FilledOutFormDocument?

    private let saveURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("forms-library.json")

    init() {
        load()
    }

    func add(_ form: FormDocument) {
        forms.insert(form, at: 0)
        save()
    }

    func update(_ form: FormDocument) {
        guard let index = forms.firstIndex(where: { $0.id == form.id }) else { return }
        forms[index] = form
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
}
