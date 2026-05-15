import SwiftUI

struct TrackerBlockerTool: Tool {
    let name = "Tracker Blocker"
    let icon = "hand.raised.fill"
    let category = ToolCategory.privacy
    let complexity = ToolComplexity.basic
    let description = "Filter outgoing requests against a maintained tracker domain list"
    let requiresAPI = false
    var view: AnyView { AnyView(TrackerBlockerView()) }
}

struct TrackerBlockerView: View {
    @StateObject private var backend = TrackerBlockerBackend()
    @State private var newDomain = ""

    var body: some View {
        ToolDetailView(tool: TrackerBlockerTool()) {
            VStack(spacing: 16) {
                enableToggle
                statsSection
                customListSection
                defaultListSection
            }
        }
        .navigationTitle("Tracker Blocker")
    }

    private var enableToggle: some View {
        ToolInputSection("Status") {
            HStack(spacing: 12) {
                Image(systemName: backend.isEnabled ? "hand.raised.fill" : "hand.raised")
                    .foregroundColor(backend.isEnabled ? .blue : .secondary)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Tracker Blocking")
                        .font(.subheadline.weight(.medium))
                    Text(backend.isEnabled
                         ? "\(backend.allTrackers.count) Domains Blocked"
                         : "Tap to enable blocking")
                        .font(.caption).foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: $backend.isEnabled).labelsHidden()
            }
            .padding()
        }
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            statCard(
                value: "\(backend.blockedCount)",
                label: "Blocked",
                icon: "shield.fill",
                color: .blue
            )
            statCard(
                value: "\(TrackerBlockerBackend.defaultTrackers.count)",
                label: "Default List",
                icon: "list.bullet.shield",
                color: .purple
            )
            statCard(
                value: "\(backend.customBlocklist.count)",
                label: "Custom",
                icon: "plus.circle.fill",
                color: .orange
            )
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(color).font(.title2)
            Text(value).font(.title3.bold())
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var customListSection: some View {
        ToolInputSection("Custom Domains") {
            VStack(spacing: 0) {
                HStack {
                    TextField("tracker.example.com", text: $newDomain)
                        .autocapitalization(.none).disableAutocorrection(true)
                        .keyboardType(.URL)
                    Button {
                        backend.addCustomDomain(newDomain)
                        newDomain = ""
                    } label: {
                        Image(systemName: "plus.circle.fill").foregroundColor(.blue)
                    }
                    .disabled(newDomain.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()

                if !backend.customBlocklist.isEmpty {
                    Divider()
                    ForEach(backend.customBlocklist, id: \.self) { domain in
                        HStack {
                            Text(domain).font(.system(.subheadline, design: .monospaced))
                            Spacer()
                            Button {
                                backend.removeCustomDomain(domain)
                            } label: {
                                Image(systemName: "minus.circle").foregroundColor(.red)
                            }
                        }
                        .padding()
                        Divider().padding(.leading)
                    }
                }
            }
        }
    }

    private var defaultListSection: some View {
        ToolInputSection("Built-in Tracker List (\(TrackerBlockerBackend.defaultTrackers.count))") {
            ForEach(Array(TrackerBlockerBackend.defaultTrackers).sorted(), id: \.self) { domain in
                HStack {
                    Image(systemName: "xmark.shield.fill")
                        .foregroundColor(.red).font(.caption)
                    Text(domain).font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal).padding(.vertical, 6)
                Divider().padding(.leading)
            }
        }
    }
}
