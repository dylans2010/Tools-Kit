import SwiftUI

private struct IntegrationItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var description: String
    var icon: String
    var category: String
    var isInstalled: Bool
}

private struct IntegrationDetailView: View {
    let item: IntegrationItem
    var body: some View {
        Text("Integration: \(item.name)")
    }
}

struct DeveloperIntegrationGalleryView: View {
    @ObservedObject var marketplaceService = MarketplaceService.shared
    @State private var selectedCategory: String = "All"
    @State private var selectedIntegration: IntegrationItem?

    let categories = ["All", "Auth", "Data", "Storage", "Analytics", "AI"]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerView

                categoryPicker

                VStack(alignment: .leading, spacing: 16) {
                    Text("Available Integrations").font(.headline)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredIntegrations) { item in
                            integrationCard(item)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Integrations")
        .sheet(item: $selectedIntegration) { (item: IntegrationItem) in
            IntegrationDetailView(item: item)
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Extend your Ecosystem").font(.title3.bold())
                    Text("Connect 3rd-party services to your workspace.").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "puzzlepiece.fill").foregroundStyle(Color.accentColor).font(.title2)
            }
        }
        .padding()
        .background(Color.accentColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(category)
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(selectedCategory == category ? Color.primary : Color(uiColor: .secondarySystemGroupedBackground))
                            .foregroundStyle(selectedCategory == category ? Color(uiColor: .systemBackground) : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func integrationCard(_ item: IntegrationItem) -> some View {
        Button {
            selectedIntegration = item
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: item.icon).font(.headline).foregroundStyle(Color.accentColor)
                    Spacer()
                    if item.isInstalled {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name).font(.subheadline.bold()).lineLimit(1)
                    Text(item.description).font(.system(size: 9)).foregroundStyle(.secondary).lineLimit(2)
                }

                HStack {
                    Text(item.category.uppercased()).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary)
                    Spacer()
                    Text("FREE").font(.system(size: 8, weight: .black)).foregroundStyle(.green)
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var filteredIntegrations: [IntegrationItem] {
        let items = [
            IntegrationItem(name: "Redis Cloud", description: "High-performance in-memory caching and data storage.", icon: "server.rack", category: "Data", isInstalled: true),
            IntegrationItem(name: "Auth0", description: "Enterprise-grade identity and access management platform.", icon: "person.badge.key", category: "Auth", isInstalled: false),
            IntegrationItem(name: "AWS S3", description: "Scalable object storage for binary assets and data blobs.", icon: "archivebox.fill", category: "Storage", isInstalled: false),
            IntegrationItem(name: "PostHog", description: "Developer-friendly product analytics and session recording.", icon: "chart.bar.fill", category: "Analytics", isInstalled: true),
            IntegrationItem(name: "OpenAI", description: "Advanced language and vision models for intelligent apps.", icon: "cpu.fill", category: "AI", isInstalled: false),
            IntegrationItem(name: "Stripe", description: "Global payment processing and billing infrastructure.", icon: "creditcard.fill", category: "Data", isInstalled: false)
        ]
        if selectedCategory == "All" { return items }
        return items.filter { $0.category == selectedCategory }
    }
}
