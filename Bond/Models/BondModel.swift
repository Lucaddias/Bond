// BondModel.swift
// Bond

import SwiftUI
import UIKit

struct BondModel: Identifiable {
    let id: UUID = UUID()
    var name: String
    var coverImage: UIImage?
    var bondDescription: String = ""
    var reward: String = ""
    var challenges: [String] = []
    var duration: Int = 0
    var posts: [PostModel] = []

    // ── Identidade e acesso ──────────────────────────────────────
    /// Código de convite gerado na criação (6 chars, A-Z + 0-9, case insensitive)
    var inviteCode: String = ""

    /// Número máximo de participantes — definido pelo tier do criador
    var maxParticipants: Int = 5

    /// Quantidade atual de membros (criador + quem entrou pelo código)
    var memberCount: Int = 1

    /// ID do criador (GKLocalPlayer.gamePlayerID ou UUID local)
    var creatorID: String = ""
}
