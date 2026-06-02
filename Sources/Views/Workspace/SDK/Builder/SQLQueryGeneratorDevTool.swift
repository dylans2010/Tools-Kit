import SwiftUI

struct SQLQueryGeneratorDevTool: DevTool {
    let id = "sql-query-generator"
    let name = "SQL Query Generator"
    let category: DevToolCategory = .data
    let icon = "plus.rectangle.fill"
    let description = "Generate basic SQL CRUD queries from table names"

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Enter Table Name") { input in
            let table = input.isEmpty ? "users" : input
            return """
            -- SELECT
            SELECT * FROM \(table) WHERE id = 1;

            -- INSERT
            INSERT INTO \(table) (name, email) VALUES ('John', 'john@example.com');

            -- UPDATE
            UPDATE \(table) SET name = 'Jane' WHERE id = 1;

            -- DELETE
            DELETE FROM \(table) WHERE id = 1;
            """
        }
    }
}
