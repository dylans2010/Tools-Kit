import SwiftUI

struct DeveloperIntegrationGalleryView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ready-to-use Integrations")
                        .font(.headline)
                    Text("Connect your apps with popular services using our verified connectors.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    integrationCard(name: "GitHub", icon: "p.circle.fill", color: .black)
                    integrationCard(name: "Slack", icon: "s.circle.fill", color: .purple)
                    integrationCard(name: "Discord", icon: "d.circle.fill", color: .indigo)
                    integrationCard(name: "AWS", icon: "a.circle.fill", color: .orange)
                }
                .padding(.horizontal)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Integration Gallery")
    }

    private func integrationCard(name: String, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(color)
            Text(name)
                .font(.headline)

            NavigationLink(destination: AuthServiceManagerView()) {
                Text("Configure")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
