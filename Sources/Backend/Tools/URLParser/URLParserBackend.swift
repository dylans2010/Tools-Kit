import Foundation

final class URLParserBackend: ObservableObject {
    @Published var components: [URLComponentItem] = []

    struct URLComponentItem: Identifiable {
        let id = UUID()
        let key: String
        let value: String
    }

    func parse(urlString: String) {
        guard let url = URL(string: urlString),
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }

        components = [
            URLComponentItem(key: "Scheme", value: comps.scheme ?? ""),
            URLComponentItem(key: "Host", value: comps.host ?? ""),
            URLComponentItem(key: "Path", value: comps.path),
            URLComponentItem(key: "Query", value: comps.query ?? ""),
            URLComponentItem(key: "Fragment", value: comps.fragment ?? "")
        ]
    }
}
