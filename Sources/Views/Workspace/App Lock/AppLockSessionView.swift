import SwiftUI

struct AppLockSessionView: View {
    @ObservedObject var manager = AppLockManager.shared
    @State var profile: AppLockProfile
    @State private var showingSelection = false

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: profile.isActive ? "lock.shield.fill" : "lock.open.fill")
                .font(.system(size: 80))
                .foregroundColor(profile.isActive ? .red : .green)
                .padding(.top, 40)

            VStack(spacing: 8) {
                Text(profile.name)
                    .font(.title.bold())

                Text(profile.isActive ? "App Lock Active" : "App Lock Ready")
                    .font(.headline)
                    .foregroundColor(profile.isActive ? .red : .secondary)

                Text(profile.isActive ? "Your selected apps are currently restricted." : "Start a session to restrict access to selected apps.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            List {
                Button(action: { showingSelection = true }) {
                    Label("Configure Apps", systemImage: "app.badge.key")
                }
            }
            .listStyle(.insetGrouped)
            .frame(height: 100)

            Spacer()

            if profile.isActive {
                Button(action: {
                    manager.endSession(for: profile.id)
                    refreshProfile()
                }) {
                    Text("End Session")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.red)
                        .cornerRadius(16)
                }
                .padding(.horizontal)
            } else {
                Button(action: {
                    manager.startSession(for: profile.id)
                    refreshProfile()
                }) {
                    Text("Start Session")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(profile.selection.applicationTokens.isEmpty && profile.selection.categoryTokens.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(16)
                }
                .disabled(profile.selection.applicationTokens.isEmpty && profile.selection.categoryTokens.isEmpty)
                .padding(.horizontal)
            }

            Text("Session state persists even if the app is closed.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
        .navigationTitle("Profile Control")
        .sheet(isPresented: $showingSelection) {
            NavigationStack {
                AppSelectionView(profile: $profile)
            }
        }
        .onAppear {
            refreshProfile()
        }
    }

    private func refreshProfile() {
        if let updated = manager.profiles.first(where: { $0.id == profile.id }) {
            self.profile = updated
        }
    }
}
