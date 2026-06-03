import SwiftUI

struct ErrorRegressionView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared

    var body: some View {
        List {
            Section("Regressed Errors") {
                Text("Errors that appeared in the current version after being absent or infrequent in previous builds.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                if store.errorRegressions.isEmpty {
                    Text("No regressions detected.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(store.errorRegressions) { regression in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(regression.errorType).font(.system(size: 11, weight: .bold, design: .monospaced))
                                Text("v\(regression.version) • \(regression.occurrences) events").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(regression.status)
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(regression.status == "Fixed" ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                                .foregroundStyle(regression.status == "Fixed" ? .green : .red)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .navigationTitle("Error Regression")
        .onAppear {
            if store.errorRegressions.isEmpty {
                store.saveErrorRegressions([
                    ErrorRegression(errorType: "NetworkTimeout", version: "1.2.0", occurrences: 124, status: "Investigating"),
                    ErrorRegression(errorType: "AuthTokenExpired", version: "1.2.0", occurrences: 82, status: "Fixed")
                ])
            }
        }
    }
}
