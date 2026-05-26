import SwiftUI

struct CalendarPublicImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var urlString = ""
    @State private var calendarName = ""
    @State private var isImporting = false
    @State private var importedCalendars: [PublicCalendar] = []

    struct PublicCalendar: Identifiable, Codable {
        let id: UUID
        let name: String
        let url: String
        var colorHex: String

        var color: Color { Color(hex: colorHex) }

        init(id: UUID = UUID(), name: String, url: String, colorHex: String = "#007AFF") {
            self.id = id
            self.name = name
            self.url = url
            self.colorHex = colorHex
        }
    }

    var body: some View {
        List {
            Section("Import New Calendar") {
                TextField("Calendar Name (e.g. Holidays)", text: $calendarName)
                TextField("ICS URL (https://...)", text: $urlString)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                Button(action: importCalendar) {
                    if isImporting {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Import Calendar").bold()
                    }
                }
                .disabled(isImporting || urlString.isEmpty || calendarName.isEmpty)
            }

            Section("Subscription Feed") {
                if importedCalendars.isEmpty {
                    Text("No external calendars imported").foregroundStyle(.secondary).font(.caption)
                } else {
                    ForEach(importedCalendars) { cal in
                        HStack {
                            Circle().fill(cal.color).frame(width: 8, height: 8)
                            VStack(alignment: .leading) {
                                Text(cal.name).font(.subheadline.bold())
                                Text(cal.url).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            Button(role: .destructive) { deleteCalendar(cal) } label: {
                                Image(systemName: "trash").font(.caption)
                            }
                        }
                    }
                }
            }

            Section {
                Text("Events from public ICS feeds are automatically merged into your agenda views.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .navigationTitle("Public Import")
        .onAppear(perform: loadCalendars)
    }

    private func importCalendar() {
        isImporting = true
        Task {
            // Simulated network delay
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            await MainActor.run {
                let newCal = PublicCalendar(name: calendarName, url: urlString)
                importedCalendars.append(newCal)
                saveCalendars()
                urlString = ""
                calendarName = ""
                isImporting = false
                SDKLogStore.shared.log("Imported public calendar: \(newCal.name)", source: "CalendarImport", level: .info)
            }
        }
    }

    private func loadCalendars() {
        if let data = UserDefaults.standard.data(forKey: "ImportedPublicCalendars"),
           let decoded = try? JSONDecoder().decode([PublicCalendar].self, from: data) {
            importedCalendars = decoded
        }
    }

    private func saveCalendars() {
        if let encoded = try? JSONEncoder().encode(importedCalendars) {
            UserDefaults.standard.set(encoded, forKey: "ImportedPublicCalendars")
        }
    }

    private func deleteCalendar(_ cal: PublicCalendar) {
        importedCalendars.removeAll { $0.id == cal.id }
        saveCalendars()
    }
}
