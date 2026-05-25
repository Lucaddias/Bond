// HomeView.swift
// Bond

import SwiftUI
import UIKit
import GameKit

struct HomeView: View {

    // ── Bonds passados de ContentView ────────────────────────────
    @Binding var bonds: [BondModel]

    // ── Sheets ───────────────────────────────────────────────────
    @State private var showCreateBond: Bool = false
    @State private var showProfile: Bool = false

    // ── Feed navegação ───────────────────────────────────────────
    @State private var selectedBondIndex: Int? = nil

    // ── Dados do Game Center ─────────────────────────────────────
    @State private var playerName: String  = ProfilePhotoStore.loadName() ?? "Player"
    @State private var playerPhoto: UIImage? = nil

    // ── Limites de tier ──────────────────────────────────────────
    private var canAddBond: Bool {
        UserManager.shared.canJoinOrCreateBond(currentCount: bonds.count)
    }
    private var existingCodes: Set<String> {
        Set(bonds.map { $0.inviteCode.uppercased() })
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ── Background ──
                Image("bg_Home")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                // ── Layout principal: header + scroll em VStack ──
                VStack(spacing: 0) {

                    // Header cobre todo o topo (safe area + conteúdo)
                    HeaderCard(name: playerName, photo: playerPhoto, onPhotoTap: {
                        showProfile = true
                    })
                    .frame(height: geo.safeAreaInsets.top + 150)

                    // Conteúdo rolável começa logo abaixo do header
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {

                            // Título da seção
                            VStack(alignment: .leading, spacing: -10) {
                                Text("YOUR BOND")
                                    .font(.app(.porkysHeavy, size: 45))
                                    .foregroundColor(.black)
                                    .kerning(1)

                                Text("CREATE YOUR EQUIP")
                                    .font(.app(.balooBold, size: 20))
                                    .foregroundColor(.black.opacity(0.5))
                                    .padding(.leading, 17)
                            }
                            .padding(.top, 15)
                            .padding(.leading, 10)
                            .padding(.horizontal, 24)

                            // Cards de Bond + botão de adicionar
                            VStack(spacing: 16) {
                                ForEach(bonds.indices, id: \.self) { index in
                                    BondCard(bond: bonds[index]) {
                                        selectedBondIndex = index
                                    }
                                }
                                AddBondCard(isLocked: !canAddBond) {
                                    showCreateBond = true
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
        }
        .ignoresSafeArea()
        .fullScreenCover(isPresented: $showCreateBond) {
            CreateABondView(onComplete: { newBond in
                let saved = try await CloudKitManager.shared.createBond(newBond)
                bonds.append(saved)
            }, existingCodes: existingCodes)
        }
        .sheet(isPresented: $showProfile, onDismiss: {
            if let saved = ProfilePhotoStore.load() {
                playerPhoto = saved
            }
            if let name = ProfilePhotoStore.loadName(), !name.isEmpty {
                playerName = name
            }
        }) {
            ProfileView()
        }
        // ── Feed do Bond selecionado ─────────────────────────────
        .fullScreenCover(
            isPresented: Binding(
                get: { selectedBondIndex != nil },
                set: { if !$0 { selectedBondIndex = nil } }
            ),
            onDismiss: {
                // Atualiza lista após sair do feed (ex: usuário saiu do bond)
                Task {
                    if let fetched = try? await CloudKitManager.shared.fetchUserBonds() {
                        bonds = fetched
                    }
                }
            }
        ) {
            if let idx = selectedBondIndex, idx < bonds.count {
                FeedView(bond: $bonds[idx], onLeaveBond: {
                    // 1. Fecha o fullScreenCover (FeedView + BondInfoView)
                    let leavingIndex = idx
                    selectedBondIndex = nil
                    // 2. Remove o bond do array local (mantém no CloudKit; só a membership foi apagada)
                    if leavingIndex < bonds.count {
                        bonds.remove(at: leavingIndex)
                    }
                })
            }
        }
        .onAppear { loadPlayerInfo() }
        .onReceive(NotificationCenter.default.publisher(for: .GKPlayerAuthenticationDidChangeNotificationName)) { _ in
            loadPlayerInfo()
        }
        .onChange(of: CloudKitManager.shared.currentPlayerName) { _, newName in
            if !newName.isEmpty && newName != "Player" {
                playerName = newName
            }
        }
    }

    private func loadPlayerInfo() {
        if let saved = ProfilePhotoStore.load() {
            playerPhoto = saved
        }
        setupAndLoadGameCenter()
    }

    private func setupAndLoadGameCenter() {
        // Nome salvo manualmente pelo usuário tem prioridade
        if let saved = ProfilePhotoStore.loadName(), !saved.isEmpty {
            playerName = saved
            return
        }
        // Fallback: nome do Game Center (só na primeira vez, sem salvar)
        let player = GKLocalPlayer.local
        if player.isAuthenticated {
            playerName = player.displayName
        }
    }
}
