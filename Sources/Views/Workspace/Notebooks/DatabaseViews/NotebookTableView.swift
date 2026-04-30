import SwiftUI

struct NotebookTableView: View {
    let tableID: UUID
    @ObservedObject var db = NotebookDatabaseEngine.shared

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                headerRow
                ForEach(db.tables[tableID] ?? []) { row in
                    dataRow(row)
                }
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            ForEach(db.schemas[tableID]?.columns ?? []) { col in
                Text(col.name)
                    .font(.caption.bold())
                    .frame(width: 120, height: 34, alignment: .leading)
                    .padding(.horizontal, 8)
                    .background(Color(.secondarySystemBackground))
                    .border(Color.primary.opacity(0.1))
            }
        }
    }

    private func dataRow(_ row: NotebookDatabaseEngine.DatabaseRow) -> some View {
        HStack(spacing: 0) {
            ForEach(db.schemas[tableID]?.columns ?? []) { col in
                TextField("", text: Binding(
                    get: { row.values[col.id] ?? "" },
                    set: { _ in }
                ))
                .frame(width: 120, height: 34)
                .padding(.horizontal, 8)
                .border(Color.primary.opacity(0.1))
            }
        }
    }
}
