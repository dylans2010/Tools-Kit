import SwiftUI

struct ConflictResolutionView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)

                Text("Merge Conflicts Detected")
                    .font(.title2.bold())

                Text("The following objects have conflicting changes. Choose which version to keep.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                List {
                    ConflictRow(objectName: "Project Plan.notebook", conflictType: "Content Conflict")
                    ConflictRow(objectName: "Budget Analysis.sheet", conflictType: "Formula Conflict")
                }

                Button(action: { dismiss() }) {
                    Text("Resolve All Conflicts")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle("Conflict Resolution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct ConflictRow: View {
    let objectName: String
    let conflictType: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(objectName).font(.headline)
                    Text(conflictType).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.left.arrow.right")
            }

            HStack {
                Button("Keep Current") { }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                Spacer()
                Button("Keep Incoming") { }
                    .buttonStyle(.bordered)
                    .tint(.green)
            }
        }
        .padding(.vertical, 8)
    }
}
