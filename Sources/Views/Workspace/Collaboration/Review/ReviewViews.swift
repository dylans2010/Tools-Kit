import SwiftUI

struct ReviewModeOverlay: View {
    let objectID: UUID
    @StateObject private var reviewManager = ReviewManager.shared

    var body: some View {
        if reviewManager.isInReviewMode(objectID: objectID) {
            VStack {
                HStack {
                    Image(systemName: "lock.shield.fill")
                    Text("Review Mode Active")
                        .bold()
                    Spacer()
                    Button("Exit") {
                        reviewManager.exitReviewMode(objectID: objectID)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding()
                .background(Color.yellow.opacity(0.9))
                .cornerRadius(12)
                .shadow(radius: 4)

                Spacer()
            }
            .padding()
            .transition(.move(edge: .top))
        } else {
            EmptyView()
        }
    }
}

struct WorkspaceSearchView: View {
    @State private var query = ""
    @State private var results: [UUID] = []

    var body: some View {
        VStack {
            TextField("Search Workspace", text: $query)
                .textFieldStyle(.roundedBorder)
                .padding()
                .onChange(of: query) { newValue in
                    results = CollaborationFramework.shared.globalSearch(query: newValue)
                }

            List {
                ForEach(results, id: \.self) { id in
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Result: \(id.uuidString.prefix(8))")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Global Search")
    }
}
