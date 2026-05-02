import SwiftUI
import UIKit

struct SpacePublishingView: View {
    let spaceID: UUID
    @StateObject private var manager = SpaceDistributionManager.shared
    @State private var isPublished = false
    @State private var publicURL: URL?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Publish Space")
                .font(.title)
                .bold()

            Text("Make your workspace accessible via a public or private link. You can also save it as a template for others.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let url = publicURL {
                VStack {
                    Text("Public Link:")
                        .font(.caption)
                    Link(url.absoluteString, destination: url)
                        .font(.headline)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }

            Button(action: {
                publicURL = manager.publishSpace(spaceID: spaceID)
                isPublished = true
            }) {
                Text(isPublished ? "Update Publication" : "Publish Now")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button("Save as Template") {
                manager.saveAsTemplate(spaceID: spaceID)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .navigationTitle("Distribution")
    }
}

struct ExternalInviteView: View {
    let spaceID: UUID
    @StateObject private var manager = ExternalCollaborationManager.shared
    @State private var inviteLink: String?

    var body: some View {
        Form {
            Section {
                Text("Generate a temporary access link for external collaborators.")
                    .font(.caption)

                Button("Generate 24h Editor Link") {
                    inviteLink = manager.generateInviteLink(spaceID: spaceID, role: .editor, duration: 86400)
                }
            } header: {
                Text("Invite Guests")
            }

            if let link = inviteLink {
                Section {
                    Text(link)
                        .font(.system(.caption, design: .monospaced))
                    Button("Copy to Clipboard") {
                        #if os(iOS)
                        UIPasteboard.general.string = link
                        #else
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(link, forType: .string)
                        #endif
                    }
                } header: {
                    Text("Your Link")
                }
            }
        }
        .navigationTitle("External Access")
    }
}
