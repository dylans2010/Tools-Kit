import SwiftUI

struct ScopeDetailSheet: View {
    let scope: DeveloperScope
    @ObservedObject var profileService = DeveloperProfileService.shared
    @ObservedObject var scopeService = DeveloperScopeService.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                headerView

                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader(title: "Overview", subtitle: nil, icon: nil)
                    Text(scope.description)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)

                    SectionHeader(title: "Requirements", subtitle: nil, icon: nil)
                    VStack(spacing: 12) {
                        requirementRow(label: "Developer Tier", value: scope.requiredTier.rawValue, met: profileService.profile.tier.rawValue >= scope.requiredTier.rawValue)
                        requirementRow(label: "Organization Audit", value: "Verified", met: !OrganizationService.shared.organizationName.isEmpty)
                    }
                }

                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader(title: "Technical Metadata", subtitle: nil, icon: nil)
                    VStack(spacing: 1) {
                        metaRow(label: "Identifier", value: scope.id)
                        metaRow(label: "Risk Level", value: scope.riskLevel.rawValue)
                        metaRow(label: "Category", value: scope.category.rawValue)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                }

                Spacer()

                Button { dismiss() } label: {
                    Text("Close Details")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(24)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var headerView: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(riskColor(scope.riskLevel).opacity(0.1))
                Image(systemName: "shield.fill").font(.title2).foregroundStyle(riskColor(scope.riskLevel))
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 2) {
                Text(scope.name).font(.headline)
                Text(scope.id).font(.system(size: 10, design: .monospaced)).foregroundStyle(.tertiary)
            }
            Spacer()
        }
    }

    private func riskColor(_ risk: ScopeRiskLevel) -> Color {
        switch risk {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }

    private func metaRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
            Spacer()
            Text(value).font(.system(size: 12, design: .monospaced))
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    private func requirementRow(label: String, value: String, met: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline.bold())
            }
            Spacer()
            Image(systemName: met ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(met ? .green : .orange)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }
}
