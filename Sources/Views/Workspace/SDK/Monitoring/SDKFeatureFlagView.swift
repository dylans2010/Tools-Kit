// ToolsKit — SDKFeatureFlagView.swift
// SDK Expansion — Phase 3

import SwiftUI

struct SDKFeatureFlagView: View {
    @StateObject private var flagService = SDKFeatureFlagService.shared
    @State private var searchText = ""
    @State private var selectedCategory: String?

    private var filteredFlags: [SDKFeatureFlag] {
        var result = flagService.allFlags
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        return result
    }

    var body: some View {
        List {
            summarySection
            filterSection
            flagsSection
            actionsSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Feature Flags")
        .searchable(text: $searchText, prompt: "Search flags")
    }

    private var summarySection: some View {
        Section("Summary") {
            let allFlags = flagService.allFlags
            LabeledContent("Total Flags", value: "\(allFlags.count)")
            LabeledContent("Enabled", value: "\(allFlags.filter(\.isEnabled).count)")
            LabeledContent("Disabled", value: "\(allFlags.filter { !$0.isEnabled }.count)")
            LabeledContent("Categories", value: "\(flagService.categories.count)")
        }
    }

    private var filterSection: some View {
        Section("Filter") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: selectedCategory == nil, action: {
                        selectedCategory = nil
                    })
                    ForEach(flagService.categories, id: \.self) { category in
                        FilterChip(title: category.capitalized, isSelected: selectedCategory == category, action: {
                            selectedCategory = category
                        })
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        }
    }

    private var flagsSection: some View {
        Section("Flags (\(filteredFlags.count))") {
            if filteredFlags.isEmpty {
                ContentUnavailableView(
                    "No Flags",
                    systemImage: "flag.slash",
                    description: Text("No feature flags match your criteria.")
                )
            } else {
                ForEach(filteredFlags) { flag in
                    FlagRow(flag: flag) { newValue in
                        flagService.setFlag(flag.name, enabled: newValue)
                    }
                }
            }
        }
    }

    private var actionsSection: some View {
        Section("Actions") {
            Button(role: .destructive) {
                flagService.resetToDefaults()
            } label: {
                Label("Reset All to Defaults", systemImage: "arrow.counterclockwise")
            }
        }
    }
}

private struct FlagRow: View {
    let flag: SDKFeatureFlag
    let onToggle: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Toggle(isOn: Binding(
                    get: { flag.isEnabled },
                    set: { onToggle($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(flag.name)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(1)
                        if !flag.description.isEmpty {
                            Text(flag.description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            HStack(spacing: 12) {
                Label(flag.category, systemImage: "tag")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                Label(flag.overrideSource.rawValue, systemImage: "arrow.triangle.branch")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                Text("Updated \(flag.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 9))
                    .foregroundStyle(.quaternary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        SDKFeatureFlagView()
    }
}
