import SwiftUI

struct CalendarHomeView: View {
    @StateObject private var manager = CalendarManager.shared
    @State private var selectedView: CalendarViewType = .month
    @State private var selectedDate = Date()
    @State private var showingCreate = false
    @State private var selectedEvent: CalendarEvent? = nil

    enum CalendarViewType: String, CaseIterable {
        case today = "Today"
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case agenda = "Agenda"

        var icon: String {
            switch self {
            case .today: return "sun.max"
            case .week: return "7.square"
            case .month: return "calendar"
            case .year: return "calendar.badge.clock"
            case .agenda: return "list.bullet"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            viewPicker

            Group {
                switch selectedView {
                case .today:
                    CalendarTodayView(selectedDate: $selectedDate, selectedEvent: $selectedEvent)
                case .week:
                    CalendarWeekView(selectedDate: $selectedDate, selectedEvent: $selectedEvent)
                case .month:
                    CalendarMonthView(selectedDate: $selectedDate, selectedView: $selectedView, selectedEvent: $selectedEvent)
                case .year:
                    CalendarYearView(selectedDate: $selectedDate, selectedView: $selectedView)
                case .agenda:
                    CalendarAgendaView(selectedEvent: $selectedEvent)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedView)
        }
        .navigationTitle("Calendar")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    selectedDate = Date()
                } label: {
                    Text("Today")
                        .font(.subheadline)
                }
                Button { showingCreate = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            NavigationStack {
                CreateEventView(prefilledDate: selectedDate) { event in
                    manager.addEvent(event)
                }
            }
        }
        .sheet(item: $selectedEvent) { event in
            NavigationStack {
                EventDetailView(event: event)
            }
        }
    }

    private var viewPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CalendarViewType.allCases, id: \.self) { type in
                    Button {
                        selectedView = type
                    } label: {
                        Label(type.rawValue, systemImage: type.icon)
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(selectedView == type ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                            .foregroundColor(selectedView == type ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}
