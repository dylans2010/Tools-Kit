import SwiftUI

struct SecurityHomeView: View {
    @ObservedObject private var authService = AuthService.shared
    @StateObject private var vaultManager = VaultManager.shared

    @State private var showingAddSheet = false
    @State private var selectedCategory: VaultCategory?
    @State private var selectedSecurityTool: SecurityToolOption?
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
        .sheet(item: $selectedSecurityTool) { tool in
            NavigationStack {
                tool.destination
            }
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

            HStack(spacing: 12) {
                Menu {
                    ForEach(SecurityToolOption.allCases) { tool in
                        Button {
                            selectedSecurityTool = tool
                        } label: {
                            Label(tool.title, systemImage: tool.icon)
                        }
                    }
                } label: {
                    Label("Open Security Tool", systemImage: "chevron.down.circle")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                }

                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Entry", systemImage: "plus.circle.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
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

enum SecurityToolOption: String, CaseIterable, Identifiable {
    case sessions, activity, trusted, autoLock, recovery, threats, biometrics, appLock, encryption, audit, permissions, emergency
    var id: String { rawValue }

    var title: String {
        switch self {
        case .sessions: return "Sessions"
        case .activity: return "Activity"
        case .trusted: return "Trusted"
        case .autoLock: return "Auto-Lock"
        case .recovery: return "Recovery"
        case .threats: return "Threats"
        case .biometrics: return "Biometrics"
        case .appLock: return "App Lock"
        case .encryption: return "Encryption"
        case .audit: return "Audit"
        case .permissions: return "Permissions"
        case .emergency: return "Emergency"
        }
    }

    var icon: String {
        switch self {
        case .sessions: return "iphone.badge.play"
        case .activity: return "list.bullet.rectangle"
        case .trusted: return "checkmark.seal"
        case .autoLock: return "timer"
        case .recovery: return "key.viewfinder"
        case .threats: return "shield.exclamationmark"
        case .biometrics: return "faceid"
        case .appLock: return "app.badge.key"
        case .encryption: return "lock.square.stack"
        case .audit: return "chart.bar.doc.horizontal"
        case .permissions: return "hand.raised.slash"
        case .emergency: return "exclamationmark.triangle"
        }
    }

    var destination: AnyView {
        switch self {
        case .sessions: return AnyView(SecuritySessionManagerView())
        case .activity: return AnyView(SecurityActivityLogView())
        case .trusted: return AnyView(SecurityDeviceTrustView())
        case .autoLock: return AnyView(SecurityAutoLockSettingsView())
        case .recovery: return AnyView(SecurityRecoveryOptionsView())
        case .threats: return AnyView(SecurityThreatDetectionView())
        case .biometrics: return AnyView(SecurityBiometricControlView())
        case .appLock: return AnyView(SecurityAppLockRulesView())
        case .encryption: return AnyView(SecurityEncryptionSettingsView())
        case .audit: return AnyView(SecurityAuditDashboardView())
        case .permissions: return AnyView(SecurityPermissionCenterView())
        case .emergency: return AnyView(SecurityEmergencyLockView())
        }
    }
}
