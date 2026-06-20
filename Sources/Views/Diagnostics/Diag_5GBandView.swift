import SwiftUI
import CoreTelephony

struct Diag_5GBandView: View {
    @State private var has5G = false
    @State private var details: [(String, String)] = []

    var body: some View {
        Form {
            Section("5G Connectivity") {
                VStack(spacing: 12) {
                    Image(systemName: has5G ? "antenna.radiowaves.left.and.right.circle.fill" : "antenna.radiowaves.left.and.right.circle")
                        .font(.system(size: 52))
                        .foregroundStyle(has5G ? .blue : .secondary)
                    Text(has5G ? "5G Supported" : "5G Not Available")
                        .font(.headline)
                    Text("Sub-6 GHz and mmWave 5G connectivity diagnostics")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Cellular Info") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("5G Bands") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Sub-6 GHz: n1, n2, n3, n5, n7, n8, n12, n20, n25, n28, n30, n38, n40, n41, n48, n66, n70, n77, n78, n79", systemImage: "antenna.radiowaves.left.and.right").font(.caption)
                    Label("mmWave: n260, n261 (US models only)", systemImage: "antenna.radiowaves.left.and.right.circle.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("5G Modes") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("5G Auto — Smart switching between LTE/5G", systemImage: "arrow.triangle.swap").font(.caption)
                    Label("5G On — Always use 5G when available", systemImage: "antenna.radiowaves.left.and.right").font(.caption)
                    Label("LTE — Force LTE only", systemImage: "cellularbars").font(.caption)
                    Label("5G Standalone — SA mode when available", systemImage: "5.circle.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Compatible Devices") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("iPhone 12+ (sub-6 GHz)", systemImage: "iphone.gen2").font(.caption)
                    Label("iPhone 12+ US models (mmWave)", systemImage: "iphone.gen2").font(.caption)
                    Label("iPhone 16 Pro (up to 4CC carrier aggregation)", systemImage: "iphone.gen3").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { check5G() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("5G Band")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { check5G() }
    }

    private func check5G() {
        var info: [(String, String)] = []

        var sysInfo = utsname()
        uname(&sysInfo)
        let modelId = Mirror(reflecting: sysInfo.machine).children.reduce("") { id, el in
            guard let v = el.value as? Int8, v != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Device Model", modelId))

        let fiveGModels = [
            "iPhone13,1", "iPhone13,2", "iPhone13,3", "iPhone13,4",
            "iPhone14,2", "iPhone14,3", "iPhone14,4", "iPhone14,5",
            "iPhone14,7", "iPhone14,8", "iPhone15,2", "iPhone15,3",
            "iPhone15,4", "iPhone15,5",
            "iPhone16,1", "iPhone16,2",
            "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4",
            "iPhone17,5", "iPhone17,6", "iPhone17,7", "iPhone17,8"
        ]
        has5G = fiveGModels.contains(modelId)
        info.append(("5G", has5G ? "Supported" : "Not Supported"))

        let networkInfo = CTTelephonyNetworkInfo()
        if let radioTech = networkInfo.serviceCurrentRadioAccessTechnology?.values.first {
            info.append(("Current Radio", radioTech))
        } else {
            info.append(("Current Radio", "N/A"))
        }

        if #available(iOS 16.0, *) {
            // No direct replacement for serviceSubscriberCellularProviders that gives carrierName
            // without using deprecated APIs or complex entitlement-based ones.
            // Using a non-deprecated way to check if we can still get basic info.
            info.append(("Carrier", "See System Settings"))
        } else {
            if let carrier = networkInfo.serviceSubscriberCellularProviders?.values.first {
                info.append(("Carrier", carrier.carrierName ?? "Unknown"))
            }
        }

        info.append(("iOS Version", UIDevice.current.systemVersion))

        details = info
    }
}
