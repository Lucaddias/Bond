// BondModel.swift
// Bond

import SwiftUI
import UIKit
import CloudKit

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
    /// ID do registro no CloudKit (nil enquanto apenas local)
    var recordID: CKRecord.ID? = nil

    /// Código de convite gerado na criação (6 chars, A-Z + 0-9, case insensitive)
    var inviteCode: String = ""

    /// Número máximo de participantes — definido pelo tier do criador
    var maxParticipants: Int = 5

    /// Quantidade atual de membros (criador + quem entrou pelo código)
    var memberCount: Int = 1

    /// ID do criador (GKLocalPlayer.gamePlayerID ou UUID local)
    var creatorID: String = ""

    /// Data de início do bond (usada para calcular o progresso de tempo)
    var startDate: Date = Date()

    /// Progresso de 0.0 a 1.0 baseado no tempo decorrido vs duração total
    var timeProgress: Double {
        guard duration > 0 else { return 0 }
        let total = Double(duration) * 86400
        let elapsed = Date().timeIntervalSince(startDate)
        return min(max(elapsed / total, 0), 1)
    }
}
