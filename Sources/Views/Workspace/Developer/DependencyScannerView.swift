import SwiftUI

struct DependencyScannerView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var isScanning = false

    var body: some View {
        List {
            Section("Security Audit") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Vulnerability Scan").font(.headline)
                        Spacer()
                        if isScanning { ProgressView() }
                    }
                    Text("Automated scanning of third-party frameworks and packages for known security vulnerabilities.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Run Security Scan") {
                        isScanning = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isScanning = false
                            var current = store.activities
                            current.append(DeveloperActivityEvent(eventType: .appUpdated, sourceAppName: "Dependency Scan Completed"))
                            store.saveActivities(current)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isScanning)
                }
                .padding(.vertical, 8)
            }

            Section("Detected Vulnerabilities") {
                if store.dependencyVulnerabilities.isEmpty {
                    Text("No vulnerabilities found.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(store.dependencyVulnerabilities) { vuln in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(vuln.package).font(.subheadline.bold())
                                Text(vuln.version).font(.caption.monospaced()).foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(vuln.severity)
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(vuln.severity == "High" ? .red : .orange)
                                Text(vuln.advisory).font(.system(size: 8)).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Dependency Scan")
        .onAppear {
            if store.dependencyVulnerabilities.isEmpty {
                store.saveDependencyVulnerabilities([
                    DependencyVulnerability(package: "Alamofire", version: "5.4.0", severity: "Low", advisory: "CVE-2023-XXXXX"),
                    DependencyVulnerability(package: "SwiftyJSON", version: "4.0.0", severity: "High", advisory: "CVE-2021-YYYYY")
                ])
            }
        }
    }
}
