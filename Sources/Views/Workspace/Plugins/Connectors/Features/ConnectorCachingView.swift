
import SwiftUI

struct ConnectorCachingView: View {
    @State private var cachingEnabled = true
    @State private var ttlMinutes = 10
    @State private var storageType: CacheStorage = .memory

    enum CacheStorage: String, CaseIterable {
        case memory, disk
    }

    var body: some View {
        Form {
            Section("Global Cache") {
                Toggle("Enable Response Caching", isOn: $cachingEnabled)
                if cachingEnabled {
                    Stepper("Time-to-Live: \(ttlMinutes) mins", value: $ttlMinutes, in: 1...1440)
                    Picker("Storage Engine", selection: $storageType) {
                        ForEach(CacheStorage.allCases, id: \.self) { e in
                            Text(e.rawValue.capitalized).tag(e)
                        }
                    }
                }
            }

            Section("Invalidation") {
                Button("Purge Connector Cache", role: .destructive) {
                    // Clear
                }
            }
        }
        .navigationTitle("Caching Strategy")
    }
}
