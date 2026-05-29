import SwiftUI

struct ScopeDetailSheet: View {
    let scope: DeveloperScope
    @ObservedObject var profileService = DeveloperProfileService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(scope.category.rawValue).font(.caption.bold()).foregroundStyle(.secondary)
                    Spacer()
                    riskBadge(scope.riskLevel)
                }

                Text(scope.name).font(.title2.bold())
                Text(scope.id).font(.caption.monospaced()).foregroundStyle(.secondary)

                Text(scope.description).font(.body)

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Requirements for this scope").font(.headline)
                        requirementRow(label: "Developer Tier", value: scope.requiredTier.rawValue, met: profileService.profile.tier.rawValue >= scope.requiredTier.rawValue)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }

    private func riskBadge(_ risk: ScopeRiskLevel) -> some View {
        Text(risk.rawValue).font(.caption2.bold())
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(riskColor(risk).opacity(0.1), in: Capsule())
            .foregroundStyle(riskColor(risk))
    }

    private func riskColor(_ risk: ScopeRiskLevel) -> Color {
        switch risk {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }

    private func requirementRow(label: String, value: String, met: Bool) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline.bold())
            }
            Spacer()
            Image(systemName: met ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(met ? .green : .orange)
        }
    }
}
