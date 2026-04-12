import Foundation

struct ManagedFileItem: Identifiable, Hashable {
    var id: String { url.path }
    let url: URL
    let isDirectory: Bool
    let size: Int64
    let modifiedAt: Date
}

enum ManagedFileType: String, CaseIterable, Identifiable {
    case text = "txt"
    case plist = "plist"
    case json = "json"
    case xml = "xml"

    var id: String { rawValue }
}

enum FileTemplate: String, CaseIterable, Identifiable {
    case html = "HTML"
    case swift = "Swift"
    case python = "Python"
    case yaml = "YAML"
    case readme = "README"

    var id: String { rawValue }

    var fileName: String {
        switch self {
        case .html:   return "index.html"
        case .swift:  return "main.swift"
        case .python: return "main.py"
        case .yaml:   return "config.yaml"
        case .readme: return "README.md"
        }
    }

    var contents: String {
        switch self {
        case .html:
            return "<!doctype html>\n<html><head><title>New File</title></head><body>\n<h1>Hello</h1>\n</body></html>\n"
        case .swift:
            return "import Foundation\n\nprint(\"Hello, world\")\n"
        case .python:
            return "def main():\n    print(\"Hello, world\")\n\nif __name__ == '__main__':\n    main()\n"
        case .yaml:
            return "name: example\nversion: 1\n"
        case .readme:
            return "# New Project\n\nDescribe your project here.\n"
        }
    }
}
