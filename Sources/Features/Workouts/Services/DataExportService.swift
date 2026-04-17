import Foundation

final class DataExportService {
    func exportJSON(snapshot: WorkoutsSnapshot, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshot)
        try data.write(to: url, options: .atomic)
    }

    func exportCSV(snapshot: WorkoutsSnapshot, to url: URL) throws {
        var csv = "date,weightKg,workoutsCompleted,caloriesBurned,caloriesConsumed,steps\n"
        let formatter = ISO8601DateFormatter()

        for item in snapshot.progress {
            let line = [
                formatter.string(from: item.date),
                item.weightKg.map { String(format: "%.2f", $0) } ?? "",
                "\(item.workoutsCompleted)",
                String(format: "%.2f", item.caloriesBurned),
                "\(item.caloriesConsumed)",
                "\(item.steps)"
            ].joined(separator: ",")
            csv.append(line + "\n")
        }

        guard let data = csv.data(using: .utf8) else { return }
        try data.write(to: url, options: .atomic)
    }

    func importSnapshot(from url: URL) throws -> WorkoutsSnapshot {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(WorkoutsSnapshot.self, from: data)
    }
}
