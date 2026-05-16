// ContentView.swift
// Bond

import SwiftUI

enum AppScreen {
    case welcome, home
}

struct ContentView: View {
    @State private var bonds: [BondModel] = []
    @State private var showCreateBond: Bool = false

    // Tela determinada pela existência de bonds
    private var screen: AppScreen {
        bonds.isEmpty ? .welcome : .home
    }

    // Códigos já em uso (para gerar código único no CreateABondView)
    private var existingCodes: Set<String> {
        Set(bonds.map { $0.inviteCode.uppercased() })
    }

    // Usuário pode criar/entrar em mais um Bond?
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
                    CreateABondView(existingCodes: existingCodes) { newBond in
                        bonds.append(newBond)
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
