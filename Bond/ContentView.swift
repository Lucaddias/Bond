// ContentView.swift
// Bond

import SwiftUI
import GameKit

enum AppScreen {
    case welcome, home
}

struct ContentView: View {
    @State private var bonds: [BondModel] = []
    @State private var showCreateBond = false
    @State private var ckError: String? = nil
    @State private var isLoadingBonds = false

    private var screen: AppScreen { bonds.isEmpty ? .welcome : .home }

    private var existingCodes: Set<String> {
        Set(bonds.map { $0.inviteCode.uppercased() })
    }
    private var canAddBond: Bool {
        UserManager.shared.canJoinOrCreateBond(currentCount: bonds.count)
    }

    var body: some View {
        ZStack {
            switch screen {
            case .welcome:
                WelcomeView(
                    bonds: $bonds,
                    onCreateTeam: {
                        if canAddBond { showCreateBond = true }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .leading),
                    removal: .move(edge: .leading)
                ))
                .fullScreenCover(isPresented: $showCreateBond) {
                    CreateABondView(existingCodes: existingCodes) { localBond in
                        // 1. Adiciona imediatamente na UI (optimistic)
                        bonds.append(localBond)
                        // 2. Persiste no CloudKit em background
                        Task {
                            do {
                                let saved = try await CloudKitManager.shared.createBond(localBond)
                                // Substitui o item local pelo salvo (com recordID)
                                if let idx = bonds.firstIndex(where: { $0.id == localBond.id }) {
                                    bonds[idx] = saved
                                }
                            } catch {
                                ckError = (error as? CloudKitError)?.errorDescription ?? error.localizedDescription
                            }
                        }
                    }
                }

            case .home:
                HomeView(bonds: $bonds)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .trailing)
                    ))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: screen)
        .onAppear { setupGameCenter() }
        // Carrega bonds do CloudKit quando o app abre
        .task {
            // setup() DEVE rodar primeiro para ter iCloudAvailable e currentPlayerID corretos
            await CloudKitManager.shared.setup()
            guard CloudKitManager.shared.iCloudAvailable else { return }
            isLoadingBonds = true
            defer { isLoadingBonds = false }
            do {
                let fetched = try await CloudKitManager.shared.fetchUserBonds()
                if !fetched.isEmpty { bonds = fetched }
            } catch {
                ckError = (error as? CloudKitError)?.errorDescription ?? error.localizedDescription
            }
        }
        .alert("Sync Error", isPresented: Binding(
            get: { ckError != nil },
            set: { if !$0 { ckError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(ckError ?? "")
        }
    }
}

// MARK: - Game Center
extension ContentView {
    private func setupGameCenter() {
        let player = GKLocalPlayer.local
        player.authenticateHandler = { viewController, _ in
            if let vc = viewController {
                UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.windows.first?.rootViewController?.present(vc, animated: true)
            } else if player.isAuthenticated {
                let name = player.displayName
                // Só salva o nome do GC se o usuário ainda não definiu um nome próprio
                if ProfilePhotoStore.loadName() == nil {
                    ProfilePhotoStore.saveName(name)
                }
                CloudKitManager.shared.currentPlayerName = ProfilePhotoStore.loadName() ?? name
                CloudKitManager.shared.currentPlayerID   = player.gamePlayerID
                if ProfilePhotoStore.load() == nil {
                    player.loadPhoto(for: .normal) { image, _ in
                        if let image {
                            DispatchQueue.main.async { ProfilePhotoStore.save(image) }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Placeholder
struct SetupABondView: View {
    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.24).ignoresSafeArea()
            Text("Setup A Bond")
                .font(.app(.porkysHeavy, size: 40))
                .foregroundColor(.white)
        }
    }
}

#Preview { ContentView() }
