// UserManager.swift
// Bond

import Foundation
import Observation

// ─────────────────────────────────────────────────────────────────
// MARK: - User Tier
// ─────────────────────────────────────────────────────────────────
enum UserTier: String, Codable {
    case free
    case premium

    /// Máximo de Bonds simultâneos que o usuário pode participar
    var maxBonds: Int {
        switch self {
        case .free:    return 1
        case .premium: return 4
        }
    }

    /// Máximo de participantes em um Bond criado por este usuário
    var maxParticipantsAsCreator: Int {
        switch self {
        case .free:    return 5
        case .premium: return 10
        }
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: - User Manager
// ─────────────────────────────────────────────────────────────────
@Observable
final class UserManager {

    static let shared = UserManager()

    private(set) var tier: UserTier = .free

    private init() {
        // Carrega tier salvo (UserDefaults)
        if let raw = UserDefaults.standard.string(forKey: "userTier"),
           let saved = UserTier(rawValue: raw) {
            tier = saved
        }
    }

    // MARK: - Validação de limites

    /// Verifica se o usuário pode criar ou entrar em mais um Bond
    func canJoinOrCreateBond(currentCount: Int) -> Bool {
        return true // Testing mode
    }

    /// Verifica se um Bond ainda aceita novos membros (baseado no tier do criador)
    func canJoinBond(_ bond: BondModel) -> Bool {
        bond.memberCount < bond.maxParticipants
    }

    // MARK: - Upgrade (StoreKit — não implementado ainda)

    /// Ativa o tier premium. Será chamado após confirmação do pagamento.
    func upgradeToPremium() {
        tier = .premium
        UserDefaults.standard.set(tier.rawValue, forKey: "userTier")
    }

    // Apenas para testes em desenvolvimento
    #if DEBUG
    func resetToFree() {
        tier = .free
        UserDefaults.standard.set(tier.rawValue, forKey: "userTier")
    }
    #endif
}
