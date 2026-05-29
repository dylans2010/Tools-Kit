import SwiftUI

struct DeveloperMonetizationView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack(spacing: 12) {
                    summaryItem(label: "Total Earnings", value: "$1,240.50", icon: "dollarsign.circle.fill", color: .green)
                    summaryItem(label: "Pending Payout", value: "$450.00", icon: "clock.fill", color: .orange)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("In-App Purchases").font(.headline)
                    ForEach(0..<3) { i in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Pro Feature Pack \(i+1)").font(.subheadline.bold())
                                Text("$9.99").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("Active").font(.caption2.bold()).foregroundStyle(.green)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Subscriptions").font(.headline)
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Monthly Subscription").font(.subheadline.bold())
                            Text("$4.99/mo").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("Active").font(.caption2.bold()).foregroundStyle(.green)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Monetization")
    }

    private func summaryItem(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundStyle(color)
            Text(value).font(.headline)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
