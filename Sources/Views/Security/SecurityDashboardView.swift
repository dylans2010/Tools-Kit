import SwiftUI

struct SecurityDashboardView: View {
    @StateObject private var vaultManager = VaultManager.shared
    @StateObject private var authService = VaultAuthService.shared
    @State private var showAddMenu = false
    @State private var selectedType: VaultItemType?
    @State private var showOnboarding = false
    @State private var showAuthGate = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if !vaultManager.config.isMasterPasswordSet {
                    welcomeView
                } else if !authService.isAuthenticated {
                    authGateView
                } else {
                    mainContent
                }
            }
            .navigationTitle("Secure Vault")
            .toolbar {
                if authService.isAuthenticated {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { showAddMenu = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button { authService.lock() } label: {
                            Image(systemName: "lock.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showOnboarding) {
                SecurityOnboardingView()
            }
            .sheet(item: $selectedType) { type in
                AddVaultItemView(type: type)
            }
            .confirmationDialog("Add Item", isPresented: $showAddMenu, titleVisibility: .visible) {
                ForEach(VaultItemType.allCases) { type in
                    Button(type.rawValue) { selectedType = type }
                }
            }
        }
        .task {
            if vaultManager.config.isMasterPasswordSet && !authService.isAuthenticated {
                _ = await authService.authenticateWithBiometrics()
                if authService.isAuthenticated {
                    try? await vaultManager.loadVault()
                }
            }
        }
    }

    private var welcomeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("Welcome to Secure Vault")
                .font(.title2.bold())

            Text("An encrypted storage for your most sensitive information. Everything is secured on-device using AES-256 and biometrics.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button("Get Started") {
                showOnboarding = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
    }

    private var authGateView: some View {
        SecurityGateView()
    }

    private var mainContent: some View {
        List {
            SearchBar(text: $searchText)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

            ForEach(VaultItemType.allCases) { type in
                let items = filteredItems.filter { $0.type == type }
                if !items.isEmpty {
                    Section(header: Text(type.rawValue)) {
                        ForEach(items) { item in
                            NavigationLink(destination: VaultItemDetailView(item: item)) {
                                VaultItemRow(item: item)
                            }
                        }
                        .onDelete { indexSet in
                            deleteItems(at: indexSet, in: type)
                        }
                    }
                }
            }

            if filteredItems.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "tray.empty")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No items found")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }

            Section("Recovery") {
                NavigationLink(destination: SecurityPackageView()) {
                    Label("Security Package (Backup)", systemImage: "archivebox")
                }
            }
        }
    }

    private var filteredItems: [VaultItem] {
        if searchText.isEmpty {
            return vaultManager.items
        } else {
            return vaultManager.items.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private func deleteItems(at offsets: IndexSet, in type: VaultItemType) {
        let itemsOfType = filteredItems.filter { $0.type == type }
        offsets.forEach { index in
            let item = itemsOfType[index]
            Task {
                try? await vaultManager.deleteItem(item)
            }
        }
    }
}

struct VaultItemRow: View {
    let item: VaultItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.type.icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.medium))
                Text(item.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
