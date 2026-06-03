import SwiftUI

struct ResourceQuotaView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Resource Quotas").font(.headline)
                    Text("Audit of allocated cloud resources across all regions.").font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

                if store.resourceQuotas.isEmpty {
                    EmptyStateView(icon: "chart.pie", title: "No Quotas", message: "Resource monitoring is not active.")
                } else {
                    ForEach(store.resourceQuotas) { quota in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(quota.name).font(.subheadline.bold())
                                Spacer()
                                Text("\(Int(quota.used))/\(Int(quota.total)) \(quota.unit)").font(.caption).foregroundStyle(.secondary)
                            }

                            ProgressView(value: quota.used / quota.total)
                                .tint(quota.used / quota.total > 0.8 ? .red : .blue)

                            Text("\(Int((quota.used / quota.total) * 100))% utilized")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Resource Quotas")
        .onAppear {
            if store.resourceQuotas.isEmpty {
                store.saveResourceQuotas([
                    ResourceQuota(name: "Compute (vCPU)", used: 42, total: 100, unit: "cores"),
                    ResourceQuota(name: "Memory (RAM)", used: 128, total: 512, unit: "GB"),
                    ResourceQuota(name: "Storage (SSD)", used: 840, total: 2000, unit: "GB")
                ])
            }
        }
    }
}
