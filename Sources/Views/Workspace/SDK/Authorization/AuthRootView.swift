import SwiftUI

struct AuthRootView: View {
    @StateObject private var authorizationManager = AuthorizationManager.shared
    @State private var showingSignInSheet = false
    @State private var showingScopeInspector = false

    var body: some View {
        NavigationStack {
            Group {
                switch authorizationManager.authState {
                case .unauthenticated:
                    stateView(title: "Unauthenticated", message: "Sign in to activate SDK authorization.")
                case .authenticating:
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Authenticating...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
