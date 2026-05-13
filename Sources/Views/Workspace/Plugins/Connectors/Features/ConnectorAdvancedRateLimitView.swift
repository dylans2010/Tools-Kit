
import SwiftUI

struct ConnectorAdvancedRateLimitView: View {
    @State private var perUserLimits = false
    @State private var burstAllowance = 10
    @State private var coolingPeriodSeconds = 60

    var body: some View {
        Form {
            Section("Throttling Strategy") {
                Toggle("Apply Per-User Limits", isOn: $perUserLimits)
                Stepper("Burst Allowance: \(burstAllowance)", value: $burstAllowance, in: 0...100)
                Stepper("Cooling Period: \(coolingPeriodSeconds)s", value: $coolingPeriodSeconds, in: 10...3600, step: 10)
            }

            Section {
                Text("Advanced rate limiting helps prevent API abuse and ensures fair resource distribution.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Advanced Rate Limiting")
    }
}
