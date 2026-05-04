import SwiftUI

struct AdvancedCollaborationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Advanced Collaboration")
                .font(.headline)
                .padding(.horizontal)

            NavigationLink(destination: LiveSessionView()) {
                CollaborationToolRow(title: "Live Sessions", icon: "person.2.wave.2.fill", description: "Real-time co-editing and presence")
            }

            NavigationLink(destination: DecisionTrackerView()) {
                CollaborationToolRow(title: "Decision Tracker", icon: "checkmark.seal.fill", description: "History of project decisions")
            }
        }
    }
}

struct CollaborationToolRow: View {
    let title: String
    let icon: String
    let description: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            VStack(alignment: .leading) {
                Text(title).font(.subheadline.bold())
                Text(description).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
