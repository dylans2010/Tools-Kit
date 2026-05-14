import SwiftUI

struct AuthRootView: View {
    @StateObject private var authorizationManager = AuthorizationManager.shared
    @State private var showingSignInSheet = false
    @State private var showingScopeInspector = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                statusHeader
                switch authorizationManager.authState {
                case .unauthenticated:
                    stateView(title: "Unauthenticated", message: "Sign in to activate SDK authorization.")
                case .authenticating:
                    Text("Authenticating...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                case .authenticated:
                    VStack(spacing: 16) {
                        if let session = authorizationManager.authSession {
                            SessionStatusView(session: session) {
                                showingScopeInspector = true
                            }
                        }
                        NavigationLink("Access Control Overview", destination: AccessControlOverviewView())
                    }
                case .sessionExpired:
                    stateView(title: "Session Expired", message: "Your SDK authorization session expired.")
                case .revoked:
                    stateView(title: "Access Revoked", message: "Authorization was revoked.")
                }
            }
            .padding()
            .navigationTitle("Authorization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(authorizationManager.authState == .authenticated ? "Sign Out" : "Sign In") {
                        if authorizationManager.authState == .authenticated {
                            authorizationManager.signOut()
                        } else {
                            showingSignInSheet = true
                        }
                    }
                }
            }
        }
        .aiAnimationLoading(authorizationManager.authState == .authenticating)
        .sheet(isPresented: $showingSignInSheet) {
            NavigationStack { SignInView() }
        }
        .fullScreenCover(isPresented: $showingScopeInspector) {
            NavigationStack {
                ScopeInspectorView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showingScopeInspector = false }
                        }
                    }
            }
        }
        .onAppear {
            showingSignInSheet = authorizationManager.authState == .unauthenticated || authorizationManager.authState == .sessionExpired || authorizationManager.authState == .revoked
        }
    }

    private var statusHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: authorizationManager.authState == .authenticated ? "checkmark.shield.fill" : "shield.lefthalf.filled")
                .font(.title3)
                .foregroundStyle(authorizationManager.authState == .authenticated ? .green : .orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("SDK Authorization Center")
                    .font(.headline)
                Text("Live state, scope controls, and session lifecycle management.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func stateView(title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Sign In") { showingSignInSheet = true }
                .buttonStyle(.borderedProminent)
            NavigationLink("Access Control Overview", destination: AccessControlOverviewView())
        }
    }
}
