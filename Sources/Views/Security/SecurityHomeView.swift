import SwiftUI

struct SecurityHomeView: View {
    @StateObject private var authService = AuthService.shared
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

            Menu {
                NavigationLink(destination: SecuritySessionManagerView()) { Label("Sessions", systemImage: "iphone.badge.play") }
                NavigationLink(destination: SecurityActivityLogView()) { Label("Activity", systemImage: "list.bullet.rectangle") }
                NavigationLink(destination: SecurityDeviceTrustView()) { Label("Trusted Devices", systemImage: "checkmark.seal") }
                NavigationLink(destination: SecurityAutoLockSettingsView()) { Label("Auto-Lock", systemImage: "timer") }
                NavigationLink(destination: SecureFoldersView()) { Label("Secure Folders", systemImage: "folder.badge.lock") }
                NavigationLink(destination: SecurityRecoveryOptionsView()) { Label("Recovery", systemImage: "key.viewfinder") }
                NavigationLink(destination: SecurityThreatDetectionView()) { Label("Threats", systemImage: "shield.exclamationmark") }
                NavigationLink(destination: SecurityBiometricControlView()) { Label("Biometrics", systemImage: "faceid") }
                NavigationLink(destination: AppLockView()) { Label("App Lock System", systemImage: "app.badge.key") }
                NavigationLink(destination: SecurityEncryptionSettingsView()) { Label("Encryption", systemImage: "lock.square.stack") }
                NavigationLink(destination: SecurityAuditDashboardView()) { Label("Audit", systemImage: "chart.bar.doc.horizontal") }
                NavigationLink(destination: SecurityPermissionCenterView()) { Label("Permissions", systemImage: "hand.raised.slash") }
                NavigationLink(destination: SecurityEmergencyLockView()) { Label("Emergency", systemImage: "exclamationmark.triangle") }
            } label: {
                HStack {
                    Label("Open Security Tools", systemImage: "chevron.down.circle")
                        .font(.subheadline.bold())
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }

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

struct CategoryCard: View {
    let category: VaultCategory
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 48, height: 48)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                Text(category.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(.primary)
                Text("\(count) item\(count == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

