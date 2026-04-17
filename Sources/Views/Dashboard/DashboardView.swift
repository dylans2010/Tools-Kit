import SwiftUI

struct DashboardView: View {
    @StateObject private var registry = ToolRegistry()
    @StateObject private var visibility = ToolVisibilityManager.shared
    @StateObject private var settingsManager = AIChatSettingsManager.shared
    @StateObject private var privateMode = PrivateModeManager.shared
    @StateObject private var musicMode = MusicModeManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: ToolCategory? = nil
    @State private var showSettings = false
    @State private var pingStatusMessage = ""

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    dashboardHeader
                    SearchBar(text: $searchText)
                    categoryPicker
                    privateModeCard
                    musicModeCard
                    sendPingCard

                    if searchText.isEmpty && selectedCategory == nil {
                        toolSection(title: "Favorites", tools: favoriteTools)
                        toolSection(title: "Recently Used", tools: recentTools)
                        toolSection(title: "Network", tools: networkTools)
                        toolSection(title: "Privacy", tools: privacyTools)
                        toolSection(title: "All Tools", tools: otherTools)
                    } else {
                        let filtered = registry.filteredTools(query: searchText, category: selectedCategory)
                            .filter { visibility.isVisible($0.id) }
                        toolSection(title: "Results", tools: filtered)
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Tools Kit")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.body)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                AIChatSettingsView(settings: $settingsManager.settings)
            }
        }
    }

    private var dashboardHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Choose your tool")
                .font(.title.bold())
            Text("\(visibleTools.count) of \(registry.tools.count) tools across \(ToolCategory.allCases.count) categories")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var privateModeCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(privateMode.isEnabled ? Color.blue : Color(.systemGray5))
                    .frame(width: 44, height: 44)
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(privateMode.isEnabled ? .white : .secondary)
                    .font(.system(size: 18, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Private Mode")
                    .font(.subheadline.weight(.semibold))
                Text(privateMode.isEnabled
                     ? "Secure Router · DoH · Tracker Blocker active"
                     : "Enable to activate all privacy protections")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $privateMode.isEnabled)
                .labelsHidden()
        }
        .padding()
        .background(
            privateMode.isEnabled
                ? LinearGradient(colors: [Color.blue.opacity(0.15), Color.indigo.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                : LinearGradient(colors: [Color(.secondarySystemGroupedBackground)], startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(privateMode.isEnabled ? Color.blue.opacity(0.4) : Color.clear, lineWidth: 1)
        )
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.25), value: privateMode.isEnabled)
    }

    private var musicModeCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(musicMode.isMusicModeEnabled ? Color.pink : Color(.systemGray5))
                    .frame(width: 44, height: 44)
                Image(systemName: "music.note.list")
                    .foregroundColor(musicMode.isMusicModeEnabled ? .white : .secondary)
                    .font(.system(size: 18, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Music Mode")
                    .font(.subheadline.weight(.semibold))
                Text(musicMode.isMusicModeEnabled
                     ? "ToolsKit is in Music mode"
                     : "Turn ToolsKit into a Music player")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if musicMode.isLocked {
                    Text("Locked by bundle identifier")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Toggle("", isOn: $musicMode.isMusicModeEnabled)
                .labelsHidden()
                .disabled(musicMode.isLocked)
        }
        .padding()
        .background(
            musicMode.isMusicModeEnabled
                ? LinearGradient(colors: [Color.pink.opacity(0.15), Color.purple.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                : LinearGradient(colors: [Color(.secondarySystemGroupedBackground)], startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(musicMode.isMusicModeEnabled ? Color.pink.opacity(0.4) : Color.clear, lineWidth: 1)
        )
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.25), value: musicMode.isMusicModeEnabled)
    }

    private var sendPingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                Task {
                    do {
                        try await AppwriteClient.shared.ping()
                        await MainActor.run {
                            pingStatusMessage = "Appwrite ping succeeded"
                        }
                    } catch {
                        await MainActor.run {
                            pingStatusMessage = "Appwrite ping failed: \(error.localizedDescription)"
                        }
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Send a ping")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)

            if !pingStatusMessage.isEmpty {
                Text(pingStatusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryTag(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(ToolCategory.allCases, id: \.self) { category in
                    CategoryTag(title: category.rawValue, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var visibleTools: [any Tool] {
        registry.tools.filter { visibility.isVisible($0.id) }
    }

    private var favoriteTools: [any Tool] {
        visibleTools.filter { registry.favoriteToolIDs.contains($0.id) }
    }

    private var recentTools: [any Tool] {
        visibleTools.filter { registry.recentlyUsedIDs.contains($0.id) }
    }

    private var networkTools: [any Tool] {
        visibleTools.filter { $0.category == .network }
    }

    private var privacyTools: [any Tool] {
        visibleTools.filter { $0.category == .privacy }
    }

    private var otherTools: [any Tool] {
        visibleTools.filter { $0.category != .network && $0.category != .privacy }
    }

    @ViewBuilder
    private func toolSection(title: String, tools: [any Tool]) -> some View {
        if !tools.isEmpty {
            SectionHeader(title: title, subtitle: "\(tools.count) tools", icon: "square.grid.2x2")
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(tools, id: \.id) { tool in
                    NavigationLink(destination: tool.view.onAppear { registry.markAsUsed(toolID: tool.id) }) {
                        ToolCard(tool: tool, isFavorite: registry.favoriteToolIDs.contains(tool.id)) {
                            registry.toggleFavorite(toolID: tool.id)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryTag: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(18)
        }
    }
}
