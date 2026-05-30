import SwiftUI

struct FAQDetailView: View {
    let title: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .font(.largeTitle.bold())

                VStack(alignment: .leading, spacing: 16) {
                    faqSection(q: "How do I get started?", a: "To get started, register your application in the 'Register App' section of the dashboard. Once registered, you will receive an App ID to use with the SDK.")

                    faqSection(q: "What are the rate limits?", a: "Standard tier developers are limited to 100 requests per minute. Enterprise tier developers have custom limits based on their agreement.")

                    faqSection(q: "How do I rotate my keys?", a: "Navigate to 'Auth & Webhooks', click the ellipsis menu next to your key, and select 'Rotate Key'. This will generate a new key and revoke the old one.")

                    faqSection(q: "Is my data secure?", a: "All data handled through the Developer Portal is encrypted at rest and in transit. We follow industry-standard security protocols to ensure your information remains private.")
                }
            }
            .padding()
        }
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func faqSection(q: String, a: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(q)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(a)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Divider()
        }
    }
}
