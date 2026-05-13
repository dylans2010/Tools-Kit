import SwiftUI

struct SecurityHomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var authService = AuthService.shared
    @StateObject private var vaultManager = VaultManager.shared
    @State private var showingAddSheet = false
    @State private var showingPackageView = false

    var body: some View {
        Group {
            if !authService.isSetup { SecurityOnboardingView(authService: authService) }
            else if !authService.isAuthenticated { SecurityLoginView(authService: authService) }
            else { dashboardContent }
        }
        .onChange(of: scenePhase) { _, newPhase in if newPhase == .background { vaultManager.saveIndex() } }
    }

    private var dashboardContent: some View {
        List {
            Section {
                Label("Security Hub", systemImage: "shield.lefthalf.filled")
                Text("Manage your vault and security tools.").font(.caption).foregroundStyle(.secondary)
            }
            Section {
                Button { showingAddSheet = true } label: { Label("Add Item", systemImage: "plus.circle.fill") }
                Button { showingPackageView = true } label: { Label("Backup & Restore", systemImage: "archivebox") }
                Button(role: .destructive) { authService.logout() } label: { Label("Lock Vault", systemImage: "lock.fill") }
            } header: {
                Text("Quick Actions")
            }
            Section {
                if vaultManager.items.isEmpty { Text("No items yet").foregroundStyle(.secondary) }
                else {
                    ForEach(vaultManager.items.sorted(by: { $0.updatedAt > $1.updatedAt })) { item in
                        NavigationLink(destination: VaultItemDetailView(item: item)) {
                            Label(item.title, systemImage: item.category.icon)
                        }
                    }
                }
            } header: {
                Text("Vault Items")
            }
        }
        .navigationTitle("Security")
        .sheet(isPresented: $showingAddSheet) { AddInfoView() }
        .sheet(isPresented: $showingPackageView) { SecurityPackageView() }
    }
}
