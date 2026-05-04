import SwiftUI

struct SecurityHomeView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var vaultManager = VaultManager.shared

    @State private var showingAddSheet = false
    @State private var showingPackageView = false
    @State private var showingEmergencyLock = false

    var body: some View {
        Group {
            if !authService.isSetup {
                SecurityOnboardingView(authService: authService)
            } else if !authService.isAuthenticated {
                SecurityLoginView(authService: authService)
            } else {
                dashboardContent
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIScene.willDeactivateNotification)) { _ in
            authService.updateActivity()
        }
        .onTapGesture {
            authService.updateActivity()
        }
    }

    private var dashboardContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                securityToolsSection

                allItemsSection
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Security Hub")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showingEmergencyLock = true
                    } label: {
                        Label("Emergency Lock", systemImage: "exclamationmark.lock.fill")
                    }

                    Button {
                        showingPackageView = true
                    } label: {
                        Label("Backup & Restore", systemImage: "archivebox")
                    }

                    Button(role: .destructive) {
                        authService.logout()
                    } label: {
                        Label("Lock Vault", systemImage: "lock.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }

            ToolbarItem(placement: .bottomBar) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Item", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddInfoView()
        }
        .sheet(isPresented: $showingPackageView) {
            SecurityPackageView()
        }
        .fullScreenCover(isPresented: $showingEmergencyLock) {
            SecurityEmergencyLockView()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Your Secure Space")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Security Dashboard")
                .font(.title2.bold())
        }
        .padding(.horizontal)
    }

    private var securityToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Security Suite")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                toolLink("Sessions", "iphone.badge.play", SecuritySessionManagerView())
                toolLink("Activity", "list.bullet.rectangle", SecurityActivityLogView())
                toolLink("Trusted Devices", "checkmark.seal", SecurityDeviceTrustView())
                toolLink("Auto-Lock", "timer", SecurityAutoLockSettingsView())
                toolLink("Recovery", "key.viewfinder", SecurityRecoveryOptionsView())
                toolLink("Threats", "shield.exclamationmark", SecurityThreatDetectionView())
                toolLink("Biometrics", "faceid", SecurityBiometricControlView())
                toolLink("App Lock", "app.badge.key", SecurityAppLockRulesView())
                toolLink("Encryption", "lock.square.stack", SecurityEncryptionSettingsView())
                toolLink("Audit", "chart.bar.doc.horizontal", SecurityAuditDashboardView())
                toolLink("Permissions", "hand.raised.slash", SecurityPermissionCenterView())
                toolLink("Emergency", "exclamationmark.triangle", SecurityEmergencyLockView())
            }
            .padding(.horizontal)

            Button {
                showingAddSheet = true
            } label: {
                HStack {
                    Label("Add Entry", systemImage: "plus.circle.fill")
                        .font(.subheadline.bold())
                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(0.12))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .buttonStyle(.plain)
        }
    }

    private var allItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Vault Items")
                .font(.headline)
                .padding(.horizontal)

            if vaultManager.items.isEmpty {
                Text("No items yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(vaultManager.items.sorted(by: { $0.updatedAt > $1.updatedAt })) { item in
                    NavigationLink {
                        VaultItemDetailView(item: item)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.category.icon)
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color.blue))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.primary)
                                Text(item.updatedAt, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func toolLink<Destination: View>(_ title: String, _ icon: String, _ destination: Destination) -> some View {
        NavigationLink(destination: destination) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
