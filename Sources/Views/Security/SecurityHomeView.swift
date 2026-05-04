import SwiftUI

struct SecurityHomeView: View {
    @ObservedObject private var authService = AuthService.shared
    @StateObject private var vaultManager = VaultManager.shared

    @State private var showingAddSheet = false
    @State private var selectedCategory: VaultCategory?
    @State private var showingPackageView = false
    @State private var showingEmergencyLock = false

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

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

                Text("Vault Categories")
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(VaultCategory.allCases) { category in
                        CategoryCard(category: category, count: vaultManager.items(for: category).count) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)

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
        .sheet(item: $selectedCategory) { category in
            NavigationStack {
                VaultListView(category: category)
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

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SecurityToolButton(title: "Sessions", icon: "iphone.badge.play", color: .blue, destination: AnyView(SecuritySessionManagerView()))
                SecurityToolButton(title: "Activity", icon: "list.bullet.rectangle", color: .green, destination: AnyView(SecurityActivityLogView()))
                SecurityToolButton(title: "Trusted", icon: "checkmark.seal", color: .orange, destination: AnyView(SecurityDeviceTrustView()))
                SecurityToolButton(title: "Auto-Lock", icon: "timer", color: .purple, destination: AnyView(SecurityAutoLockSettingsView()))
                SecurityToolButton(title: "Recovery", icon: "key.viewfinder", color: .red, destination: AnyView(SecurityRecoveryOptionsView()))
                SecurityToolButton(title: "Threats", icon: "shield.exclamationmark", color: .indigo, destination: AnyView(SecurityThreatDetectionView()))
                SecurityToolButton(title: "Biometrics", icon: "faceid", color: .teal, destination: AnyView(SecurityBiometricControlView()))
                SecurityToolButton(title: "App Lock", icon: "app.badge.key", color: .pink, destination: AnyView(SecurityAppLockRulesView()))
                SecurityToolButton(title: "Encryption", icon: "lock.square.stack", color: .cyan, destination: AnyView(SecurityEncryptionSettingsView()))
                SecurityToolButton(title: "Audit", icon: "chart.bar.doc.horizontal", color: .brown, destination: AnyView(SecurityAuditDashboardView()))
                SecurityToolButton(title: "Permissions", icon: "hand.raised.slash", color: .yellow, destination: AnyView(SecurityPermissionCenterView()))
                SecurityToolButton(title: "Emergency", icon: "exclamationmark.triangle", color: .red, destination: AnyView(SecurityEmergencyLockView()))
            }
            .padding(.horizontal)
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

struct SecurityToolButton: View {
    let title: String
    let icon: String
    let color: Color
    let destination: AnyView

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                Text(title)
                    .font(.caption2.bold())
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
