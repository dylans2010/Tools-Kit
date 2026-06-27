import SwiftUI
public struct LARequestView: View {
    @State private var viewModel = LARequestViewModel()
    public var body: some View { ProgressView("Waiting for Approval...") }
}
