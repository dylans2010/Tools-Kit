import SwiftUI
import Darwin

struct Diag_IOSVersionDetailView: View {
    @State private var versionInfo: [(String, String)] = []
    @State private var featureSupport: [(String, Bool)] = []

    var body: some View {
        Form {
            Section("iOS Version Details") {
                VStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 44))
                    Text("iOS \(UIDevice.current.systemVersion)")
                        .font(.title.bold())
                    Text(UIDevice.current.model)
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("System Details") {
                ForEach(versionInfo, id: \.0) { info in
                    LabeledContent(info.0) { Text(info.1).font(.caption.monospaced()) }
                }
            }

            Section("Feature Support") {
                ForEach(featureSupport, id: \.0) { feature in
                    HStack {
                        Image(systemName: feature.1 ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundStyle(feature.1 ? .green : .secondary)
                        Text(feature.0).font(.subheadline)
                    }
                }
            }

            Section { Button { loadInfo() } label: { HStack { Image(systemName: "arrow.clockwise"); Text("Refresh") } } }
        }
        .navigationTitle("iOS Version")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadInfo() }
    }

    private func loadInfo() {
        var info: [(String, String)] = []
        let device = UIDevice.current
        let pi = ProcessInfo.processInfo
        let version = pi.operatingSystemVersion

        info.append(("System Name", device.systemName))
        info.append(("Version", device.systemVersion))
        info.append(("Major", "\(version.majorVersion)"))
        info.append(("Minor", "\(version.minorVersion)"))
        info.append(("Patch", "\(version.patchVersion)"))
        info.append(("Build", pi.operatingSystemVersionString))

        var sysInfo = utsname()
        uname(&sysInfo)
        let kernel = Mirror(reflecting: sysInfo.release).children.reduce("") { str, el in
            guard let v = el.value as? Int8, v != 0 else { return str }
            return str + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Kernel", kernel))

        let machine = Mirror(reflecting: sysInfo.machine).children.reduce("") { str, el in
            guard let v = el.value as? Int8, v != 0 else { return str }
            return str + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("Machine", machine))

        let sysname = Mirror(reflecting: sysInfo.sysname).children.reduce("") { str, el in
            guard let v = el.value as? Int8, v != 0 else { return str }
            return str + String(UnicodeScalar(UInt8(v)))
        }
        info.append(("OS Type", sysname))

        versionInfo = info

        var features: [(String, Bool)] = []
        let major = version.majorVersion
        features.append(("SwiftUI", major >= 13))
        features.append(("Widgets", major >= 14))
        features.append(("App Library", major >= 14))
        features.append(("Focus Modes", major >= 15))
        features.append(("SharePlay", major >= 15))
        features.append(("Lock Screen Widgets", major >= 16))
        features.append(("Live Activities", major >= 16))
        features.append(("StandBy Mode", major >= 17))
        features.append(("Interactive Widgets", major >= 17))
        features.append(("Journal App", major >= 17))
        features.append(("Apple Intelligence", major >= 18))

        featureSupport = features
    }
}
