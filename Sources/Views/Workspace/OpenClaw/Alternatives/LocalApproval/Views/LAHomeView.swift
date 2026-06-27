import SwiftUI
public struct LAHomeView: View {
    @State private var pairingVM = LAPairingViewModel()
    public var body: some View { List { Button("Request Access") { Task { await pairingVM.startPairing(host: "localhost", port: 9876) } } }.navigationTitle("Local Approval") }
}
