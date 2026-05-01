import SwiftUI

struct GuestAccessView: View {
    @StateObject private var accessManager = ExternalAccessManager.shared
    let spaceID: UUID

    @State private var guestEmail = ""
    @State private var selectedRole: SpaceRole = .viewer
    @State private var showInviteResult = false
    @State private var generatedLink = ""

    var body: some View {
        List {
            Section(header: Text("Invite External Guest")) {
                TextField("Email Address", text: $guestEmail)
                    .keyboardType(.emailAddress)

                Picker("Role", selection: $selectedRole) {
                    Text("Viewer").tag(SpaceRole.viewer)
                    Text("Commenter").tag(SpaceRole.commenter)
                }

                Button("Generate Invite Link") {
                    generatedLink = accessManager.inviteGuest(spaceID: spaceID, email: guestEmail, role: selectedRole, duration: 86400 * 7) // 7 days
                    showInviteResult = true
                }
                .disabled(!guestEmail.contains("@"))
            }

            Section(header: Text("Current Guests")) {
                ForEach(accessManager.guestsBySpace[spaceID] ?? []) { guest in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(guest.email).bold()
                            Text(guest.role.rawValue).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        if let expiry = guest.expiresAt {
                            Text("Expires \(expiry, style: .date)")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            accessManager.revokeAccess(spaceID: spaceID, guestID: guest.id)
                        } label: {
                            Label("Revoke", systemImage: "xmark.circle")
                        }
                    }
                }
            }
        }
        .navigationTitle("Guest Access")
        .alert("Invite Generated", isPresented: $showInviteResult) {
            Button("Copy Link") { UIPasteboard.general.string = generatedLink }
            Button("OK", role: .cancel) { }
        } message: {
            Text("Send this link to the guest: \(generatedLink)")
        }
    }
}
