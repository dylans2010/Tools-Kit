import SwiftUI

struct AgenticUIWorkspaceInspectorView: View {
    @StateObject private var orchestrator = AgenticCoreOrchestrator.shared
    @State private var selectedDomain: String?
    @State private var searchQuery: String = ""
    @State private var isAnalyzing: Bool = false

    private var graph: WorkspaceGraph? { orchestrator.workspaceGraph }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                overviewCard
                searchBar
                domainFilterBar
                modulesSection
                relationshipsSection
                capabilitiesSection
            }
            .padding()
        }
    }

    // MARK: - Overview Card

    private var overviewCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "folder.badge.gearshape")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Workspace Graph")
                        .font(.headline)
                    if let graph = graph {
                        Text("Scanned \(graph.scannedAt, style: .relative) ago")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button {
                    rescanWorkspace()
                } label: {
                    if isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Label("Rescan", systemImage: "arrow.clockwise")
                            .font(.caption)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isAnalyzing)
            }

            if let graph = graph {
                HStack(spacing: 16) {
                    metricBadge(value: "\(graph.modules.count)", label: "Modules")
                    metricBadge(value: "\(graph.totalFileCount)", label: "Files")
                    metricBadge(value: "\(graph.featureDomains.count)", label: "Domains")
                    metricBadge(value: "\(graph.relationships.count)", label: "Relations")
                }
            } else {
                Text("Workspace not analyzed yet. Tap 'Rescan' to begin.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func metricBadge(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.weight(.bold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search modules, declarations...", text: $searchQuery)
                .textFieldStyle(.plain)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Domain Filter

    private var domainFilterBar: some View {
        Group {
            if let graph = graph, !graph.featureDomains.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button {
                            selectedDomain = nil
                        } label: {
                            Text("All")
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedDomain == nil ? Color.accentColor : Color(.systemGray5))
                                .foregroundStyle(selectedDomain == nil ? .white : .primary)
                                .clipShape(Capsule())
                        }

                        ForEach(graph.featureDomains, id: \.self) { domain in
                            Button {
                                selectedDomain = selectedDomain == domain ? nil : domain
                            } label: {
                                Text(domain)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedDomain == domain ? Color.accentColor : Color(.systemGray5))
                                    .foregroundStyle(selectedDomain == domain ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Modules

    @ViewBuilder
    private var modulesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "square.stack.3d.up")
                    .foregroundStyle(Color.accentColor)
                Text("Modules")
                    .font(.headline)
                Spacer()
                Text("\(filteredModules.count)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Capsule())
            }

            if filteredModules.isEmpty {
                Text("No modules match the current filter.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(filteredModules, id: \.id) { module in
                    moduleRow(module)
                }
            }
        }
    }

    private var filteredModules: [WorkspaceModule] {
        guard let graph = graph else { return [] }
        var modules = graph.modules

        if let domain = selectedDomain {
            modules = modules.filter { $0.domain == domain }
        }

        if !searchQuery.isEmpty {
            modules = modules.filter { module in
                module.name.localizedCaseInsensitiveContains(searchQuery) ||
                module.domain.localizedCaseInsensitiveContains(searchQuery) ||
                module.declarations.contains { $0.name.localizedCaseInsensitiveContains(searchQuery) }
            }
        }

        return modules
    }

    private func moduleRow(_ module: WorkspaceModule) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    statBadge(value: module.structCount, label: "Structs", color: .blue)
                    statBadge(value: module.classCount, label: "Classes", color: .purple)
                    statBadge(value: module.enumCount, label: "Enums", color: .orange)
                    statBadge(value: module.protocolCount, label: "Protocols", color: .green)
                }

                if !module.declarations.isEmpty {
                    Text("Declarations:")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    ForEach(module.declarations.prefix(10), id: \.id) { decl in
                        HStack(spacing: 6) {
                            Text(decl.kind.rawValue)
                                .font(.system(.caption2, design: .monospaced))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(declarationKindColor(decl.kind).opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 4))

                            Text(decl.name)
                                .font(.caption)

                            if !decl.conformances.isEmpty {
                                Text(": \(decl.conformances.joined(separator: ", "))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if module.declarations.count > 10 {
                        Text("... and \(module.declarations.count - 10) more")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.vertical, 4)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(module.name)
                        .font(.subheadline.weight(.semibold))
                    Text(module.domain)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Label("\(module.files.count)", systemImage: "doc")
                    Label("\(module.declarations.count)", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func statBadge(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text("\(value)")
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Relationships

    private var relationshipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundStyle(Color.accentColor)
                Text("Relationships")
                    .font(.headline)
                Spacer()
                if let graph = graph {
                    Text("\(graph.relationships.count)")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            if let graph = graph, !graph.relationships.isEmpty {
                ForEach(graph.relationships.prefix(20), id: \.id) { relation in
                    HStack(spacing: 8) {
                        Text(relation.sourceModuleID.components(separatedBy: "/").last ?? relation.sourceModuleID)
                            .font(.caption)
                            .lineLimit(1)

                        Image(systemName: relationIcon(relation.kind))
                            .font(.caption2)
                            .foregroundStyle(relationColor(relation.kind))

                        Text(relation.targetModuleID.components(separatedBy: "/").last ?? relation.targetModuleID)
                            .font(.caption)
                            .lineLimit(1)

                        Spacer()

                        Text(relation.kind.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(relationColor(relation.kind).opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .padding(6)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            } else {
                Text("No relationships detected.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }

    // MARK: - Capabilities

    private var capabilitiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.accentColor)
                Text("Detected Capabilities")
                    .font(.headline)
            }

            if let graph = graph {
                let capabilities = AgenticWorkspaceAnalyzer.shared.detectExistingCapabilities(from: graph)
                let missing = AgenticWorkspaceAnalyzer.shared.detectMissingCapabilities(from: graph)

                ForEach(capabilities.sorted(by: { $0.key < $1.key }), id: \.key) { domain, caps in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(domain)
                            .font(.subheadline.weight(.semibold))

                        HStack(spacing: 6) {
                            ForEach(caps, id: \.self) { cap in
                                Text(cap)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.green.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if !missing.isEmpty {
                    Text("Identified Gaps")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                        .padding(.top, 4)

                    ForEach(missing, id: \.self) { gap in
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text(gap)
                                .font(.caption)
                        }
                        .padding(8)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func rescanWorkspace() {
        isAnalyzing = true
        Task {
            do {
                let graph = try await AgenticWorkspaceAnalyzer.shared.analyzeWorkspace()
                orchestrator.workspaceGraph = graph
            } catch {
                // Error handled by orchestrator diagnostics
            }
            isAnalyzing = false
        }
    }

    private func declarationKindColor(_ kind: DeclarationKind) -> Color {
        switch kind {
        case .structDecl: return .blue
        case .classDecl: return .purple
        case .enumDecl: return .orange
        case .protocolDecl: return .green
        case .extensionDecl: return .gray
        case .actorDecl: return .cyan
        }
    }

    private func relationIcon(_ kind: RelationKind) -> String {
        switch kind {
        case .imports: return "arrow.right"
        case .conformsTo: return "arrow.right.circle"
        case .dependsOn: return "arrow.right.square"
        case .contains: return "arrow.down.right"
        }
    }

    private func relationColor(_ kind: RelationKind) -> Color {
        switch kind {
        case .imports: return .blue
        case .conformsTo: return .green
        case .dependsOn: return .orange
        case .contains: return .purple
        }
    }
}
