import SwiftUI
import Network
public struct TLANPairingView: View {
    let result: NWBrowser.Result; @State private var viewModel = TLANPairingViewModel()
    public var body: some View {
        VStack(spacing: 20) { ProgressView().controlSize(.large); Text("Requesting Approval...").font(.title2); Text("Please check your Mac for an approval dialog.").foregroundStyle(.secondary).multilineTextAlignment(.center)
            if let e = viewModel.lastError { Text(e).foregroundStyle(.red).font(.caption) }
        }.padding().navigationTitle("Pairing")
    }
}
