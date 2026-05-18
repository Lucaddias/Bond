// ContentView.swift
// Bond

import SwiftUI

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
                .sheet(isPresented: $showCreateBond) {
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
        // Carrega bonds do CloudKit quando o app abre
        .task {
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
