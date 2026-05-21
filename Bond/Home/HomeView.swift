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
            CreateABondView(existingCodes: existingCodes) { newBond in
                bonds.append(newBond)
            }
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
                // Só substitui bonds se o resultado não for vazio (evita apagar tudo por falha de rede)
                Task {
                    if let fetched = try? await CloudKitManager.shared.fetchUserBonds(),
                       !fetched.isEmpty {
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

// ─────────────────────────────────────────────────────────────────
// MARK: - Header Card
// ─────────────────────────────────────────────────────────────────
struct HeaderCard: View {
    let name: String
    let photo: UIImage?
    var onPhotoTap: () -> Void = {}

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                Color.white

                HStack(alignment: .center) {
                    Text("HI, \(name)!")
                        .font(.app(.balooBold, size: 36))
                        .foregroundColor(.black.opacity(0.5))
                        .padding(.top, 60)
                        .padding(.leading, 20)
                        .padding(35)

                    // Foto do Game Center — clicável para ir ao Perfil
                    Button(action: onPhotoTap) {
                        Group {
                            if let photo {
                                Image(uiImage: photo)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(12)
                                    .foregroundColor(.black.opacity(0.50))
                            }
                        }
                        .frame(width: 85, height: 85)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(red: 0.90, green: 0.90, blue: 0.92), lineWidth: 2))
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 42)
                }
                .padding(.leading, 12)
                .padding(.bottom, 24)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 60,
                    bottomTrailingRadius: 60,
                    topTrailingRadius: 0
                )
            )
            .shadow(color: .black.opacity(0.30), radius: 12, x: 0, y: 6)
        }
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: - Bond Card
// ─────────────────────────────────────────────────────────────────
struct BondCard: View {
    let bond: BondModel
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let img = bond.coverImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle()
                            .fill(Color(red: 0.85, green: 0.85, blue: 0.87))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Text(bond.name)
                    .font(.app(.balooBold, size: 22))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: - Add Bond Card
// ─────────────────────────────────────────────────────────────────
struct AddBondCard: View {
    var isLocked: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: isLocked ? {} : action) {
            ZStack {
                RoundedRectangle(cornerRadius: 60)
                    .fill(isLocked ? Color(red: 0.93, green: 0.93, blue: 0.95) : Color.white)
                    .shadow(color: .black.opacity(isLocked ? 0.06 : 0.3), radius: 12, x: 5, y: 4)

                if isLocked {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.black.opacity(0.25))
                        Text("Bond limit reached")
                            .font(.app(.balooBold, size: 15))
                            .foregroundColor(.black.opacity(0.30))
                        Text("Upgrade to Premium for more")
                            .font(.app(.balooMedium, size: 12))
                            .foregroundColor(.black.opacity(0.20))
                    }
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.black)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────────────────────────
#Preview {
    HomeView(bonds: .constant([]))
}
