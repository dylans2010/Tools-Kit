import SwiftUI

struct Diag_DynamicIslandView: View {
    @State private var hasDynamicIsland = false
    @State private var details: [(String, String)] = []
    @State private var current: DeviceModelInfo = DeviceModelCatalog.currentInfo()
    @State private var note: String = ""

    var body: some View {
        Form {
            Section("Dynamic Island") {
                VStack(spacing: 12) {
                    Image(systemName: hasDynamicIsland ? "pill.circle.fill" : "pill.circle")
                        .font(.system(size: 52))
                        .foregroundStyle(hasDynamicIsland ? .purple : .secondary)
                    Text(hasDynamicIsland ? "Dynamic Island Available" : "Dynamic Island Not Available")
                        .font(.headline)
                    Text("Interactive pill-shaped display cutout for live activities and alerts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    if current.isProvisional {
                        Text("Provisional result for an unrecognised or unreleased model — see note below.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Device Info") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
                if !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Dynamic Island Features") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Live Activities display", systemImage: "clock.badge.fill").font(.caption)
                    Label("Music now playing controls", systemImage: "music.note").font(.caption)
                    Label("Timer and stopwatch", systemImage: "timer").font(.caption)
                    Label("Navigation directions", systemImage: "location.fill").font(.caption)
                    Label("Phone call status", systemImage: "phone.fill").font(.caption)
                    Label("AirDrop progress", systemImage: "square.and.arrow.down.fill").font(.caption)
                    Label("AirPods connection", systemImage: "airpodspro").font(.caption)
                    Label("Food delivery tracking", systemImage: "bag.fill").font(.caption)
                    Label("Sports scores live", systemImage: "sportscourt.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 14 Pro / Pro Max", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 15 (all models)", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 16 (all models except 16e)", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 17, iPhone 17 Pro / Pro Max, iPhone Air", systemImage: "iphone.gen3").font(.caption)
                    Label("iPhone 18 Pro / Pro Max, iPhone Duo (provisional)", systemImage: "iphone.gen3").font(.caption)
                    Text("Not Dynamic Island: iPhone 14 / 14 Plus (notch), iPhone 16e and iPhone 17e (notch).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Supported Lineup") {
                ForEach(DeviceModelCatalog.supportedLineup) { model in
                    HStack {
                        Text(model.marketingName)
                            .font(.subheadline)
                        Spacer()
                        Text(model.isProvisional ? "Provisional" : (model.hasDynamicIsland ? "Dynamic Island" : "Notch"))
                            .font(.caption)
                            .foregroundStyle(model.isProvisional ? .orange : (model.hasDynamicIsland ? .green : .secondary))
                    }
                }
            }

            Section {
                Button { checkDynamicIsland() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Dynamic Island")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkDynamicIsland() }
    }

    private func checkDynamicIsland() {
        // Single source of truth — no more copy-pasted identifier lists here.
        // This is the fix for iPhone 17 reporting "Not Available": the old
        // list stopped at iPhone17,x (iPhone 16 generation) and never
        // contained iPhone18,1–iPhone18,4.
        let info = DeviceModelCatalog.currentInfo()
        current = info
        hasDynamicIsland = info.hasDynamicIsland
        note = info.note

        var rows: [(String, String)] = []
        rows.append(("Device Model", info.marketingName))
        rows.append(("Model Identifier", info.identifier ?? "Not published yet"))
        rows.append(("Chip", info.chip))
        rows.append(("Dynamic Island", hasDynamicIsland ? "Present" : "Not present"))
        rows.append(("Catalog Status", info.isProvisional ? "Provisional" : "Confirmed"))
        let screenBounds = UIScreen.main.bounds
        rows.append(("Screen Size", "\(Int(screenBounds.width)) x \(Int(screenBounds.height))"))
        rows.append(("Scale", "\(Int(UIScreen.main.scale))x"))
        rows.append(("iOS Version", UIDevice.current.systemVersion))
        details = rows
    }
}
