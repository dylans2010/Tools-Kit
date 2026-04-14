import SwiftUI
import WebKit

struct MailThreadView: View {
    @ObservedObject var viewModel: MailViewModel
    let email: EmailMessage

    var body: some View {
        EmailDetailView(viewModel: viewModel, email: email)
    }
}
