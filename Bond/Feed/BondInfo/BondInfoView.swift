import SwiftUI
import PhotosUI
import CloudKit

struct BondInfoView: View {

    @Binding var bond: BondModel
    var onLeaveBond: () -> Void = {}
    @Environment(\.dismiss) private var dismiss

    // ── Cover photo ──────────────────────────────────────────────
    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var showCameraForCover = false

    // ── Share sheet ──────────────────────────────────────────────
    @State private var showShare = false
    @State private var codeCopied = false

    // ── Leave bond ───────────────────────────────────────────────
    @State private var showLeaveAlert = false
    @State private var leaveErrorMessage: String? = nil
    @State private var coverErrorMessage: String? = nil

    // ── Membros derivados dos posts ───────────────────────────────
    private var members: [(name: String, photo: UIImage?, postCount: Int)] {
        var dict: [String: (name: String, photo: UIImage?, count: Int)] = [:]
        for post in bond.posts {
            let key = post.authorPlayerID.isEmpty ? post.authorName : post.authorPlayerID
            if var existing = dict[key] {
                existing.count += 1
                dict[key] = existing
            } else {
                dict[key] = (post.authorName, post.authorPhoto, 1)
            }
        }
        return dict.values
            .map { (name: $0.name, photo: $0.photo, postCount: $0.count) }
            .sorted { $0.postCount > $1.postCount }
    }

    private var maxPosts: Int { members.map(\.postCount).max() ?? 1 }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {

                // ── Background ───────────────────────────────────
                Image("bg_BondInfo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                // ── Conteúdo scrollável ──────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // ── Header: voltar + sair ────────────────
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                ZStack {
                                    Image("Botao_voltar")
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button {
                                showLeaveAlert = true
                            } label: {
                                ZStack {
                                    Image("Botao_sair")
                                        .scaleEffect(x: -1, y: 1)
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, max(geo.safeAreaInsets.top, 44) + 16)

                        // ── Foto do Bond + botão share ───────────
                        ZStack(alignment: .bottomTrailing) {
                            Group {
                                if let img = bond.coverImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Image("bg_BondFoto")
                                        .resizable()
                                        .scaledToFill()
                                }
                            }
                            .frame(width: 160, height: 160)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)

                            // Botão trocar foto (camera + galeria)
                            Menu {
                                Button {
                                    showCameraForCover = true
                                } label: {
                                    Label("Camera", systemImage: "camera")
                                }
                                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                                    Label("Library", systemImage: "photo.on.rectangle")
                                }
                            } label: {
                                Image("Botao_Adicionar_Foto")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 44, height: 44)
                            }
                        }

                        // ── Nome do Bond + botão Share ───────────
                        // ZStack: nome sempre centralizado na largura total;
                        // botão de compartilhar fixo à esquerda, antes do nome.
                        ZStack {
                            Text(bond.name)
                                .font(.app(.balooBold, size: 28))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)

                            HStack {
                                Button {
                                    showShare = true
                                } label: {
                                    Image("Botao_compartilhar")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 44, height: 44)
                                }
                                .buttonStyle(.plain)
                                .padding(.leading, 24)

                                Spacer()
                            }
                        }

                        // ── Progress / Time ──────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("PROGRESS/time")
                                    .font(.app(.balooBold, size: 14))
                                    .foregroundColor(.black)
                                Spacer()
                                if bond.duration > 0 {
                                    let daysLeft = max(0, bond.duration - Int(Date().timeIntervalSince(bond.startDate) / 86400))
                                    Text("\(daysLeft) days left")
                                        .font(.app(.balooMedium, size: 12))
                                        .foregroundColor(.black.opacity(0.5))
                                }
                            }

                            GeometryReader { bar in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.6))
                                        .frame(height: 12)

                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 1.0, green: 0.45, blue: 0.10),
                                                    Color(red: 1.0, green: 0.85, blue: 0.10)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(
                                            width: bar.size.width * bond.timeProgress,
                                            height: 12
                                        )
                                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: bond.timeProgress)
                                }
                            }
                            .frame(height: 12)
                        }
                        .padding(.horizontal, 24)

                        // ── Rewards + Challenges ─────────────────
                        HStack(alignment: .top, spacing: 16) {

                            // Rewards
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Text("🏆")
                                    Text("REWARDS")
                                        .font(.app(.balooBold, size: 14))
                                        .foregroundColor(.black)
                                }

                                if bond.reward.isEmpty {
                                    Text("No reward set")
                                        .font(.app(.balooMedium, size: 13))
                                        .foregroundColor(.black.opacity(0.35))
                                } else {
                                    Text(bond.reward)
                                        .font(.app(.balooMedium, size: 13))
                                        .foregroundColor(.black.opacity(0.7))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(16)
                            .background(Color.white.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                            // Challenges
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Challenges")
                                    .font(.app(.balooBold, size: 14))
                                    .foregroundColor(.black)

                                if bond.challenges.isEmpty {
                                    Text("No challenges set")
                                        .font(.app(.balooMedium, size: 13))
                                        .foregroundColor(.black.opacity(0.35))
                                } else {
                                    VStack(alignment: .leading, spacing: 6) {
                                        ForEach(bond.challenges, id: \.self) { challenge in
                                            HStack(alignment: .top, spacing: 4) {
                                                Text("•")
                                                    .foregroundColor(.black.opacity(0.5))
                                                Text(challenge)
                                                    .font(.app(.balooMedium, size: 13))
                                                    .foregroundColor(.black.opacity(0.7))
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(16)
                            .background(Color.white.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        .padding(.horizontal, 24)

                        // ── Members ──────────────────────────────
                        VStack(alignment: .leading, spacing: 16) {
                            Text("members")
                                .font(.app(.balooBold, size: 18))
                                .foregroundColor(.black)

                            Divider()

                            if members.isEmpty {
                                Text("No posts yet")
                                    .font(.app(.balooMedium, size: 13))
                                    .foregroundColor(.black.opacity(0.35))
                            } else {
                                ForEach(members, id: \.name) { member in
                                    MemberRow(
                                        name: member.name,
                                        photo: member.photo,
                                        postCount: member.postCount,
                                        maxPosts: maxPosts
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, geo.safeAreaInsets.bottom + 40)
                    }
                }
            }
        }
        .ignoresSafeArea()
        // ── Trocar foto via galeria ──────────────────────────────
        .onChange(of: photoPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await saveCover(image)
                }
            }
        }
        // ── Trocar foto via câmera ───────────────────────────────
        .fullScreenCover(isPresented: $showCameraForCover) {
            CameraPickerView(
                image: Binding(
                    get: { nil },
                    set: { img in
                        if let img {
                            Task { await saveCover(img) }
                        }
                    }
                ),
                videoURL: .constant(nil)
            )
            .ignoresSafeArea()
        }
        // ── Share sheet ──────────────────────────────────────────
        .sheet(isPresented: $showShare) {
            ShareCodeSheet(
                bondName: bond.name,
                inviteCode: bond.inviteCode,
                maxParticipants: bond.maxParticipants,
                copied: $codeCopied
            )
            .presentationDetents([.medium, .large])
        }
        // ── Alerta: sair do Bond ─────────────────────────────────
        .alert("Leave Bond?", isPresented: $showLeaveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Leave", role: .destructive) {
                Task {
                    do {
                        if let id = bond.recordID {
                            try await CloudKitManager.shared.leaveBond(bondRecordID: id)
                        }
                        // Volta direto pra home: dispara callback do parent que
                        // remove o bond do array e fecha as covers
                        onLeaveBond()
                    } catch {
                        await MainActor.run {
                            leaveErrorMessage = (error as? CloudKitError)?.errorDescription ?? error.localizedDescription
                        }
                    }
                }
            }
        } message: {
            Text("Are you sure you want to leave \"\(bond.name)\"? You'll need the invite code to rejoin.")
        }
        .alert("Couldn't leave Bond", isPresented: Binding(
            get: { leaveErrorMessage != nil },
            set: { if !$0 { leaveErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(leaveErrorMessage ?? "")
        }
        .alert("Couldn't update photo", isPresented: Binding(
            get: { coverErrorMessage != nil },
            set: { if !$0 { coverErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(coverErrorMessage ?? "")
        }
    }

    private func saveCover(_ image: UIImage) async {
        await MainActor.run { bond.coverImage = image }
        guard let id = bond.recordID else { return }
        do {
            try await CloudKitManager.shared.updateBondCover(bondRecordID: id, image: image)
        } catch {
            await MainActor.run {
                coverErrorMessage = (error as? CloudKitError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────
