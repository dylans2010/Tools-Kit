// ToolsKit — SDKCacheInspectorView.swift
// SDK Expansion — Phase 3

import SwiftUI

struct SDKCacheInspectorView: View {
    @StateObject private var cacheManager = SDKCacheManager.shared
    @State private var searchText = ""
    @State private var showingClearConfirmation = false

    private var filteredEntries: [CacheEntryInfo] {
        let entries = cacheManager.allEntryInfo()
        guard !searchText.isEmpty else { return entries }
        return entries.filter { $0.key.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            statsSection
            performanceSection
            entriesSection
            actionsSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Cache Inspector")
        .searchable(text: $searchText, prompt: "Search Cache Keys")
        .confirmationDialog("Clear Cache", isPresented: $showingClearConfirmation) {
            Button("Clear All", role: .destructive) { cacheManager.removeAll() }
            Button("Clear Expired Only") { cacheManager.removeExpired() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var statsSection: some View {
        Section(header: Text("Cache Statistics")) {
            LabeledContent("Entries", value: "\(cacheManager.entryCount)")
            LabeledContent("Total Size", value: ByteCountFormatter.string(fromByteCount: Int64(cacheManager.totalSizeBytes), countStyle: .memory))
        }
    }

    private var performanceSection: some View {
        Section(header: Text("Performance")) {
            LabeledContent("Hits", value: "\(cacheManager.hitCount)")
            LabeledContent("Misses", value: "\(cacheManager.missCount)")
            LabeledContent("Hit Rate", value: String(format: "%.1f%%", cacheManager.hitRate * 100))

            if cacheManager.hitCount + cacheManager.missCount > 0 {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: geometry.size.width * cacheManager.hitRate)
                        Rectangle()
                            .fill(Color.red.opacity(0.5))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .frame(height: 8)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
    }

    private var entriesSection: some View {
        Section(header: Text("Entries (\(filteredEntries.count))")) {
            if filteredEntries.isEmpty {
                ContentUnavailableView(
                    "No Cache Entries",
                    systemImage: "archivebox",
                    description: Text("The cache is empty or no entries match your search.")
                )
            } else {
                ForEach(filteredEntries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.key)
                                .font(.system(.caption, design: .monospaced))
                                .lineLimit(1)
                            Spacer()
                            if entry.isExpired {
                                Text("EXPIRED")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(.red)
                            }
                        }
                        HStack(spacing: 12) {
                            Label(
                                ByteCountFormatter.string(fromByteCount: Int64(entry.sizeBytes), countStyle: .memory),
                                systemImage: "doc"
                            )
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                            if let expiresAt = entry.expiresAt {
                                Label(expiresAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            } else {
                                Label("No Expiry", systemImage: "infinity")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            cacheManager.remove(forKey: entry.key)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var actionsSection: some View {
        Section(header: Text("Actions")) {
            Button {
                showingClearConfirmation = true
            } label: {
                Label("Clear Cache", systemImage: "trash")
            }

            Button {
                cacheManager.resetStats()
            } label: {
                Label("Reset Statistics", systemImage: "arrow.counterclockwise")
            }
        }
    }
}

#Preview {
    NavigationStack {
        SDKCacheInspectorView()
    }
}
