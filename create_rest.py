import os

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(content.strip() + "\n")

# M2 - PairingCode
write_file("Sources/Views/Workspace/OpenClaw/Alternatives/PairingCode/Views/PCHomeView.swift", """
import SwiftUI
public struct PCHomeView: View {
    public var body: some View {
        List { Section("Method") { Text("Pairing Code").font(.headline); Text("Your Mac generates an 8-digit code. Type it into your iPhone to pair.").font(.subheadline).foregroundStyle(.secondary) }
            Section { NavigationLink("Enter Pairing Code") { PCCodeEntryView() } }
            Section { NavigationLink("User Guide") { PCGuideView() } }
        }.navigationTitle("Pairing Code")
    }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/PairingCode/Views/PCCodeEntryView.swift", """
import SwiftUI
public struct PCCodeEntryView: View {
    @State private var viewModel = PCCodeEntryViewModel(); @State private var pairingVM = PCPairingViewModel()
    public var body: some View {
        VStack(spacing: 30) { Text("Enter the 8-digit code shown on your Mac").font(.headline); TextField("00000000", text: $viewModel.code).font(.system(size: 40, weight: .bold, design: .monospaced)).keyboardType(.numberPad).multilineTextAlignment(.center).padding()
            Button("Pair") { Task { await pairingVM.submitCode(viewModel.code, host: "localhost", port: 9876) } }.buttonStyle(.borderedProminent).disabled(!viewModel.isValid)
            if pairingVM.state == .submitting { ProgressView() }
        }.padding().navigationTitle("Enter Code")
    }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/PairingCode/Views/PCPairingView.swift", """
import SwiftUI
public struct PCPairingView: View {
    @State private var viewModel = PCPairingViewModel()
    public var body: some View { VStack { if viewModel.state == .submitting { ProgressView("Validating Code...") } }.navigationTitle("Pairing") }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/PairingCode/Views/PCStatusView.swift", """
import SwiftUI
public struct PCStatusView: View { public var body: some View { Text("PC Status").navigationTitle("Pairing Code Status") } }
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/PairingCode/Views/PCDiagnosticsView.swift", """
import SwiftUI
public struct PCDiagnosticsView: View {
    @State private var viewModel = PCDiagnosticsViewModel()
    public var body: some View { List { Section("Stats") { LabeledContent("Attempts", value: "\\(viewModel.attemptCount)") } }.navigationTitle("PC Diagnostics") }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/PairingCode/Views/PCSettingsView.swift", """
import SwiftUI
public struct PCSettingsView: View {
    @State private var settings = PCSettingsService.shared
    public var body: some View { Form { Section("Gateway") { TextField("URL", text: $settings.gatewayURL) } }.navigationTitle("PC Settings") }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/PairingCode/Views/PCGuideView.swift", """
import SwiftUI
public struct PCGuideView: View {
    public var body: some View { ScrollView { VStack(alignment: .leading, spacing: 20) { Text("Your Mac generates a temporary 8-digit code. Type it into your iPhone.").font(.body).foregroundStyle(.secondary) } }.padding().navigationTitle("User Guide") }
}
""")

# M3 - QRCode
write_file("Sources/Views/Workspace/OpenClaw/Alternatives/QRCode/Views/QRHomeView.swift", """
import SwiftUI
public struct QRHomeView: View {
    @State private var scannerVM = QRScannerViewModel()
    public var body: some View {
        List { Section("Method") { Text("QR Code Pairing").font(.headline) }
            Section { if scannerVM.hasPermission { NavigationLink("Open Scanner") { QRScannerView() } } else { Button("Grant Permission") { Task { await scannerVM.checkPermission() } } } }
        }.navigationTitle("QR Code").task { await scannerVM.checkPermission() }
    }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/QRCode/Views/QRScannerView.swift", """
import SwiftUI
public struct QRScannerView: View {
    @State private var pairingVM = QRPairingViewModel(); private let bridge = QRScannerBridge()
    public var body: some View { QRScannerRepresentable(bridge: bridge) { result in Task { await pairingVM.handleScanResult(result) } }.navigationTitle("Scan QR Code") }
}
struct QRScannerRepresentable: UIViewRepresentable {
    let bridge: QRScannerBridge; let onScan: (String) -> Void
    func makeUIView(context: Context) -> UIView { let view = UIView(frame: .zero); bridge.startScanning(in: view, completion: onScan); return view }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/QRCode/Views/QRPairingView.swift", """
import SwiftUI
public struct QRPairingView: View { public var body: some View { ProgressView("Pairing...") } }
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/QRCode/Views/QRStatusView.swift", """
import SwiftUI
public struct QRStatusView: View { public var body: some View { Text("QR Status") } }
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/QRCode/Views/QRPermissionView.swift", """
import SwiftUI
public struct QRPermissionView: View { public var body: some View { Text("Permission Required") } }
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/QRCode/Views/QRDiagnosticsView.swift", """
import SwiftUI
public struct QRDiagnosticsView: View { public var body: some View { Text("QR Diagnostics") } }
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/QRCode/Views/QRSettingsView.swift", """
import SwiftUI
public struct QRSettingsView: View {
    @State private var settings = QRSettingsService.shared
    public var body: some View { Form { Toggle("Auto Connect", isOn: $settings.autoConnect) } }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/QRCode/Views/QRGuideView.swift", """
import SwiftUI
public struct QRGuideView: View { public var body: some View { Text("QR Guide") } }
""")

# M4 - ManualToken
write_file("Sources/Views/Workspace/OpenClaw/Alternatives/ManualToken/Views/MTHomeView.swift", """
import SwiftUI
public struct MTHomeView: View {
    public var body: some View { List { Section("Method") { Text("Manual Token") }; NavigationLink("Paste Token") { MTPasteView() } }.navigationTitle("Manual Token") }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/ManualToken/Views/MTPasteView.swift", """
import SwiftUI
public struct MTPasteView: View {
    @State private var viewModel = MTPasteViewModel(); @State private var pairingVM = MTPairingViewModel()
    public var body: some View { VStack { TextField("Token", text: $viewModel.token); Button("Validate") { Task { await pairingVM.pair(token: viewModel.token, host: "localhost", port: 9876) } } } }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/ManualToken/Views/MTPairingView.swift", """
import SwiftUI
public struct MTPairingView: View { public var body: some View { ProgressView("Pairing...") } }
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/ManualToken/Views/MTStatusView.swift", """
import SwiftUI
public struct MTStatusView: View { public var body: some View { Text("MT Status") } }
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/ManualToken/Views/MTDiagnosticsView.swift", """
import SwiftUI
public struct MTDiagnosticsView: View { public var body: some View { Text("MT Diagnostics") } }
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/ManualToken/Views/MTSettingsView.swift", """
import SwiftUI
public struct MTSettingsView: View {
    @State private var settings = MTSettingsService.shared
    public var body: some View { Form { TextField("Host", text: $settings.gatewayHost) } }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/ManualToken/Views/MTGuideView.swift", """
import SwiftUI
public struct MTGuideView: View { public var body: some View { Text("MT Guide") } }
""")

# M5 - LocalApproval
write_file("Sources/Views/Workspace/OpenClaw/Alternatives/LocalApproval/Views/LAHomeView.swift", """
import SwiftUI
public struct LAHomeView: View {
    @State private var pairingVM = LAPairingViewModel()
    public var body: some View { List { Button("Request Access") { Task { await pairingVM.startPairing(host: "localhost", port: 9876) } } }.navigationTitle("Local Approval") }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/LocalApproval/Views/LARequestView.swift", """
import SwiftUI
public struct LARequestView: View {
    @State private var viewModel = LARequestViewModel()
    public var body: some View { ProgressView("Waiting for Approval...") }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/LocalApproval/Views/LAPairingView.swift", """
import SwiftUI
public struct LAPairingView: View { public var body: some View { ProgressView("Pairing...") } }
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/LocalApproval/Views/LAStatusView.swift", """
import SwiftUI
public struct LAStatusView: View { public var body: some View { Text("LA Status") } }
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/LocalApproval/Views/LADeviceListView.swift", """
import SwiftUI
public struct LADeviceListView: View { public var body: some View { Text("LA Devices") } }
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/LocalApproval/Views/LADiagnosticsView.swift", """
import SwiftUI
public struct LADiagnosticsView: View { public var body: some View { Text("LA Diagnostics") } }
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/LocalApproval/Views/LASettingsView.swift", """
import SwiftUI
public struct LASettingsView: View {
    @State private var settings = LASettingsService.shared
    public var body: some View { Form { Stepper("Timeout: \\(Int(settings.approvalTimeout))s", value: $settings.approvalTimeout) } }
}
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/LocalApproval/Views/LAGuideView.swift", """
import SwiftUI
public struct LAGuideView: View { public var body: some View { Text("LA Guide") } }
""")

write_file("Sources/Views/Workspace/OpenClaw/Alternatives/LocalApproval/Views/LAReconnectView.swift", """
import SwiftUI
public struct LAReconnectView: View { public var body: some View { Text("LA Reconnect") } }
""")
