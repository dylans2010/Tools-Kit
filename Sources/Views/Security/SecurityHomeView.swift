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

                recentItemsSection
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

            let tools: [(String, String, AnyView)] = [
                ("Sessions", "iphone.badge.play", AnyView(SecuritySessionManagerView())),
                ("Activity", "list.bullet.rectangle", AnyView(SecurityActivityLogView())),
                ("Trusted Devices", "checkmark.seal", AnyView(SecurityDeviceTrustView())),
                ("Auto-Lock", "timer", AnyView(SecurityAutoLockSettingsView())),
                ("Recovery", "key.viewfinder", AnyView(SecurityRecoveryOptionsView())),
                ("Threats", "shield.exclamationmark", AnyView(SecurityThreatDetectionView())),
                ("Biometrics", "faceid", AnyView(SecurityBiometricControlView())),
                ("App Lock", "app.badge.key", AnyView(SecurityAppLockRulesView())),
                ("Encryption", "lock.square.stack", AnyView(SecurityEncryptionSettingsView())),
                ("Audit", "chart.bar.doc.horizontal", AnyView(SecurityAuditDashboardView())),
                ("Permissions", "hand.raised.slash", AnyView(SecurityPermissionCenterView()))
            ]

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(0..<tools.count, id: \.self) { idx in
                    NavigationLink(destination: tools[idx].2) {
                        Label(tools[idx].0, systemImage: tools[idx].1)
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
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
                    NavigationLink(destination: VaultItemDetailView(item: item)) {
                        HStack(spacing: 12) {
                            Image(systemName: item.category.icon)
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color.accentColor))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.subheadline.bold())
                                Text(item.category.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recentItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently Updated")
                .font(.headline)
                .padding(.horizontal)

            if vaultManager.items.isEmpty {
                Text("No items yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(vaultManager.items.sorted(by: { $0.updatedAt > $1.updatedAt }).prefix(3)) { item in
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
}

