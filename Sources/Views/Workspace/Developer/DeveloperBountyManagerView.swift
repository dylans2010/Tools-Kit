import SwiftUI

struct DeveloperBountyManagerView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var showingAdd = false
    @State private var title = ""
    @State private var description = ""
    @State private var amount = 500.0

    var body: some View {
        List {
            Section("Rewards Program") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Incentivize your developer community with bounties for bug fixes, documentation, or feature requests.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

                Button(action: { showingAdd = true }) {
                    Label("Post New Bounty", systemImage: "bitcoinsign.circle.fill")
                }
            }

            Section("Active Bounties") {
                if store.bounties.isEmpty {
                    Text("No active bounties.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.bounties) { bounty in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(bounty.title).font(.subheadline.bold())
                                Spacer()
                                Text(String(format: "$%.0f", bounty.rewardAmount))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.green)
                            }
                            Text(bounty.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)

                            HStack {
                                statusBadge(bounty.status)
                                Spacer()
                                Text(bounty.createdAt, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteBounty)
                }
            }
        }
        .navigationTitle("Bounty Manager")
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                Form {
                    Section("Bounty Details") {
                        TextField("Title", text: $title)
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                    }
                    Section("Reward") {
                        HStack {
                            Text("Amount")
                            Spacer()
                            TextField("Amount", value: $amount, format: .currency(code: "USD"))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                .navigationTitle("Post Bounty")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAdd = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Post") { saveBounty() }
                            .disabled(title.isEmpty)
                    }
                }
            }
        }
    }

    private func saveBounty() {
        let new = DeveloperBounty(title: title, description: description, rewardAmount: amount)
        var updated = store.bounties
        updated.append(new)
        store.saveBounties(updated)

        title = ""
        description = ""
        showingAdd = false
    }

    private func deleteBounty(at offsets: IndexSet) {
        var updated = store.bounties
        updated.remove(atOffsets: offsets)
        store.saveBounties(updated)
    }

    private func statusBadge(_ status: DeveloperBounty.BountyStatus) -> some View {
        let color: Color = {
            switch status {
            case .open: return .blue
            case .inProgress: return .orange
            case .underReview: return .purple
            case .completed: return .green
            case .cancelled: return .gray
            }
        }()

        return Text(status.rawValue.uppercased())
            .font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
