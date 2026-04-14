import SwiftUI

struct CalendarHomeView: View {
    @StateObject private var manager = CalendarManager.shared
    @State private var selectedView: CalendarViewType = .month
    @State private var selectedDate = Date()
    @State private var showingCreate = false
    @State private var selectedEvent: CalendarEvent? = nil

    enum CalendarViewType: String, CaseIterable {
        case month = "Month"
        case today = "Today"
        case week = "Week"
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
            Group {
                switch selectedView {
                case .month:
                    CalendarMonthView(selectedDate: $selectedDate, selectedView: $selectedView, selectedEvent: $selectedEvent)
                case .today:
                    CalendarTodayView(selectedDate: $selectedDate, selectedEvent: $selectedEvent)
                case .week:
                    CalendarWeekView(selectedDate: $selectedDate, selectedEvent: $selectedEvent)
                case .year:
                    CalendarYearView(selectedDate: $selectedDate, selectedView: $selectedView)
                case .agenda:
                    CalendarAgendaView(selectedEvent: $selectedEvent)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selectedView)

            Spacer(minLength: 0)

            viewPicker
                .padding(.bottom, 10)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    withAnimation {
                        selectedDate = Date()
                    }
                } label: {
                    Text("Today")
                        .font(.subheadline.bold())
                }

                Button { showingCreate = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
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
        HStack(spacing: 0) {
            ForEach(CalendarViewType.allCases, id: \.self) { type in
                Button {
                    selectedView = type
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: type.icon)
                            .font(.system(size: 18))
                        Text(type.rawValue)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(selectedView == type ? .blue : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 10)
        .background(.ultraThinMaterial)
    }
}
