import SwiftUI

struct OpenClawAltView: View {
    @State private var viewModel = OpenClawAltViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(viewModel.methodCards) { card in
                    NavigationLink(destination: destination(for: card.id)) {
                        AltMethodCardView(card: card)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Alternative Pairing")
    }

    @ViewBuilder
    func destination(for id: String) -> some View {
        switch id {
        case "tlan": TLANHomeView()
        case "pc": PCHomeView()
        case "qr": QRHomeView()
        case "mt": MTHomeView()
        case "la": LAHomeView()
        default: Text("Unknown")
        }
    }
}

struct AltMethodCardView: View {
    let card: OpenClawAltMethodCard
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(card.name).font(.headline)
                Spacer()
                if card.isRecommended {
                    Text("Recommended").font(.caption).padding(4).background(Color.yellow.opacity(0.3)).cornerRadius(4)
                }
            }
            Text(card.tagline).font(.subheadline).foregroundColor(.secondary)
            HStack {
                Label(card.securityLevel.rawValue, systemImage: "lock.shield")
                Label(card.estimatedSetupTime, systemImage: "clock")
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
