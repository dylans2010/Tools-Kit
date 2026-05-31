import SwiftUI

struct DeveloperIntegrationGalleryView: View {
    @ObservedObject var marketplaceService = MarketplaceService.shared
    @State private var selectedCategory: String = "All"
    @State private var showingDetails = false
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
        .navigationTitle("Integration Gallery")
        .sheet(item: $selectedIntegration) { item in
            IntegrationDetailView(item: item)
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Extend your Ecosystem").font(.title2.bold())
            Text("Connect powerful 3rd-party services and SDK plugins with a single click.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.accentColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(category)
                            .font(.caption.bold())
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(selectedCategory == category ? Color.accentColor : Color(uiColor: .secondarySystemGroupedBackground))
                            .foregroundStyle(selectedCategory == category ? .white : .primary)
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
                    Image(systemName: item.icon).font(.title3).foregroundStyle(.accentColor)
                    Spacer()
                    if item.isInstalled {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name).font(.subheadline.bold()).lineLimit(1)
                    Text(item.description).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(2)
                }

                HStack {
                    Text(item.category).font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                    Spacer()
                    Text("Free").font(.system(size: 8, weight: .bold)).foregroundStyle(.green)
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
            IntegrationItem(name: "Redis Cloud", description: "In-memory data structure store, used as a database.", icon: "server.rack", category: "Data", isInstalled: true),
            IntegrationItem(name: "Auth0", description: "Identity platform for application teams.", icon: "person.badge.key", category: "Auth", isInstalled: false),
            IntegrationItem(name: "AWS S3", description: "Object storage built to retrieve any amount of data.", icon: "archivebox.fill", category: "Storage", isInstalled: false),
            IntegrationItem(name: "PostHog", description: "Product analytics and feature flags for devs.", icon: "chart.bar.fill", category: "Analytics", isInstalled: true),
            IntegrationItem(name: "OpenAI", description: "Integrate advanced AI models into your app.", icon: "cpu.fill", category: "AI", isInstalled: false),
            IntegrationItem(name: "Stripe", description: "Online payment processing for internet businesses.", icon: "creditcard.fill", category: "Data", isInstalled: false)
        ]
        if selectedCategory == "All" { return items }
        return items.filter { $0.category == selectedCategory }
    }
}

struct IntegrationItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let category: String
    let isInstalled: Bool
}

struct IntegrationDetailView: View {
    let item: IntegrationItem
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 20) {
                        Image(systemName: item.icon).font(.system(size: 40)).foregroundStyle(.accentColor)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name).font(.title3.bold())
                            Text(item.category).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.primary.opacity(0.02))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("Overview").font(.headline)
                    Text(item.description + " This integration allows you to seamlessly connect your app to external services with zero configuration overhead.")
                        .font(.subheadline).foregroundStyle(.secondary)

                    SectionHeader(title: "Required Scopes", subtitle: nil, icon: nil)
                    VStack(alignment: .leading, spacing: 8) {
                        scopeRow("network.external", "Access to 3rd party API endpoints.")
                        scopeRow("data.sync", "Synchronize application state with integration.")
                    }

                    Spacer()

                    Button {
                        // install logic
                        dismiss()
                    } label: {
                        Text(item.isInstalled ? "Configure" : "Add to Project")
                            .font(.headline).frame(maxWidth: .infinity).padding()
                            .background(Color.accentColor).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
    }

    private func scopeRow(_ id: String, _ desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(.secondary.opacity(0.2)).frame(width: 4, height: 4).padding(.top, 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(id).font(.caption.monospaced()).bold()
                Text(desc).font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
    }
}
