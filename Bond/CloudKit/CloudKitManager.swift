// CloudKitManager.swift
// Bond

import CloudKit
import UIKit
import GameKit
import Observation

// ─────────────────────────────────────────────────────────────────
// MARK: - CloudKit Record Type Names
// ─────────────────────────────────────────────────────────────────
private enum RecordType {
    static let bond       = "Bond"
    static let membership = "BondMembership"
    static let post       = "Post"
    static let like       = "Like"
}

// ─────────────────────────────────────────────────────────────────
// MARK: - CloudKit Manager
// ─────────────────────────────────────────────────────────────────
@MainActor
@Observable
final class CloudKitManager {

    static let shared = CloudKitManager()

    // ── Estado público ───────────────────────────────────────────
    var isLoading      = false
    var iCloudAvailable = false
    var currentPlayerID  = ""
    var currentPlayerName = "Player"

    // ── Infra ────────────────────────────────────────────────────
    private let container = CKContainer(identifier: "iCloud.com.seuteam.Bond")
    private var db: CKDatabase { container.publicCloudDatabase }

    private init() {}

    // ─────────────────────────────────────────────────────────────
    // MARK: - Setup
    // ─────────────────────────────────────────────────────────────

    /// Verifica iCloud e popula o playerID do Game Center.
    func setup() async {
        do {
            let status = try await container.accountStatus()
            iCloudAvailable = (status == .available)
        } catch {
            iCloudAvailable = false
        }

        // Player ID via Game Center (fallback para UUID local)
        let player = GKLocalPlayer.local
        if player.isAuthenticated {
            currentPlayerID = player.gamePlayerID
            // Respeita nome salvo manualmente; só usa GC na primeira vez
            if ProfilePhotoStore.loadName() == nil {
                ProfilePhotoStore.saveName(player.displayName)
            }
            currentPlayerName = ProfilePhotoStore.loadName() ?? player.displayName
        } else {
            // Fallback para nome salvo manualmente pelo usuário
            currentPlayerName = ProfilePhotoStore.loadName() ?? "Player"
            let key = "localPlayerID"
            if let saved = UserDefaults.standard.string(forKey: key) {
                currentPlayerID = saved
            } else {
                let generated = UUID().uuidString
                UserDefaults.standard.set(generated, forKey: key)
                currentPlayerID = generated
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: - Bond Operations
    // ─────────────────────────────────────────────────────────────

    /// Cria um Bond no CloudKit com o código já gerado localmente.
    func createBond(_ bond: BondModel) async throws -> BondModel {
        guard iCloudAvailable else { throw CloudKitError.iCloudNotAvailable }

        // Garante unicidade do código no servidor
        if let _ = try await fetchBondRecord(byCode: bond.inviteCode) {
            throw CloudKitError.codeAlreadyExists
        }

        let record = CKRecord(recordType: RecordType.bond)
        record["name"]            = bond.name
        record["inviteCode"]      = bond.inviteCode.uppercased()
        record["maxParticipants"] = bond.maxParticipants as CKRecordValue
        record["memberCount"]     = 1 as CKRecordValue
        record["creatorID"]       = currentPlayerID

        do {
            let saved = try await db.save(record)
            try await createMembership(bondRecordID: saved.recordID)

            var result = bond
            result.recordID = saved.recordID
            return result
        } catch {
            throw CloudKitError.from(error)
        }
    }

    /// Entra num Bond existente pelo código de convite.
    func joinBond(code: String, currentBondCount: Int) async throws -> BondModel {
        guard iCloudAvailable else { throw CloudKitError.iCloudNotAvailable }

        guard UserManager.shared.canJoinOrCreateBond(currentCount: currentBondCount) else {
            throw CloudKitError.bondFull   // reuse — significa limite do usuário
        }

        guard let bondRecord = try await fetchBondRecord(byCode: code) else {
            throw CloudKitError.bondNotFound
        }

        let memberCount    = bondRecord["memberCount"]    as? Int ?? 1
        let maxParticipants = bondRecord["maxParticipants"] as? Int ?? 5

        guard memberCount < maxParticipants else { throw CloudKitError.bondFull }

        let alreadyMember = try await checkMembership(bondRecordID: bondRecord.recordID)
        guard !alreadyMember else { throw CloudKitError.alreadyMember }

        // Cria membership e incrementa contador
        try await createMembership(bondRecordID: bondRecord.recordID)
        bondRecord["memberCount"] = (memberCount + 1) as CKRecordValue
        do {
            _ = try await db.save(bondRecord)
        } catch {
            throw CloudKitError.from(error)
        }

        return try bondFromRecord(bondRecord)
    }

    /// Busca todos os Bonds dos quais o usuário é membro.
    func fetchUserBonds() async throws -> [BondModel] {
        guard iCloudAvailable else { return [] }

        let predicate = NSPredicate(format: "playerID == %@", currentPlayerID)
        let query     = CKQuery(recordType: RecordType.membership, predicate: predicate)

        do {
            let (results, _) = try await db.records(matching: query)
            var bonds: [BondModel] = []

            for (_, result) in results {
                guard let membership  = try? result.get(),
                      let bondRef     = membership["bondRef"] as? CKRecord.Reference,
                      let bondRecord  = try? await db.record(for: bondRef.recordID),
                      let bond        = try? bondFromRecord(bondRecord) else { continue }
                bonds.append(bond)
            }

            return bonds
        } catch {
            throw CloudKitError.from(error)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: - Post Operations
    // ─────────────────────────────────────────────────────────────

    /// Busca os posts de um Bond (mais recentes primeiro, paginado em 50).
    func fetchPosts(for bondRecordID: CKRecord.ID) async throws -> [PostModel] {
        guard iCloudAvailable else { return [] }

        let bondRef   = CKRecord.Reference(recordID: bondRecordID, action: .none)
        let predicate = NSPredicate(format: "bondRef == %@", bondRef)
        let query     = CKQuery(recordType: RecordType.post, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        do {
            let (results, _) = try await db.records(matching: query, resultsLimit: 50)
            return results.compactMap { (_, result) in try? result.get() }.map(postFromRecord)
        } catch {
            throw CloudKitError.from(error)
        }
    }

    /// Remove o usuário atual de um Bond (apaga o BondMembership dele).
    func leaveBond(bondRecordID: CKRecord.ID) async throws {
        guard iCloudAvailable else { throw CloudKitError.iCloudNotAvailable }

        let bondRef   = CKRecord.Reference(recordID: bondRecordID, action: .none)
        let predicate = NSPredicate(format: "bondRef == %@ AND playerID == %@", bondRef, currentPlayerID)
        let query     = CKQuery(recordType: RecordType.membership, predicate: predicate)

        let (results, _) = try await db.records(matching: query)
        for (recordID, result) in results {
            if (try? result.get()) != nil {
                try await db.deleteRecord(withID: recordID)
            }
        }
    }

    /// Salva um novo Post no CloudKit (com upload de asset se necessário).
    func createPost(_ post: PostModel, bondRecordID: CKRecord.ID) async throws -> PostModel {
        guard iCloudAvailable else { throw CloudKitError.iCloudNotAvailable }

        let record  = CKRecord(recordType: RecordType.post)
        let bondRef = CKRecord.Reference(recordID: bondRecordID, action: .deleteSelf)

        record["bondRef"]        = bondRef
        record["authorPlayerID"] = currentPlayerID
        record["authorName"]     = post.authorName
        record["caption"]        = post.caption
        record["timestamp"]      = post.timestamp
        record["likesCount"]     = 0 as CKRecordValue

        if let image = post.image {
            record["imageAsset"] = try encodeImageAsset(image)
            record["mediaType"]  = "image"
        } else if let videoURL = post.videoURL {
            record["videoAsset"] = CKAsset(fileURL: videoURL)
            record["mediaType"]  = "video"
        }

        do {
            let saved = try await db.save(record)
            var result          = post
            result.recordID     = saved.recordID
            result.bondRecordID = bondRecordID
            result.authorPlayerID = currentPlayerID
            return result
        } catch {
            throw CloudKitError.from(error)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: - Like Operations
    // ─────────────────────────────────────────────────────────────

    /// Alterna like num post. Retorna o novo estado e contagem.
    func toggleLike(postRecordID: CKRecord.ID) async throws -> (isLiked: Bool, count: Int) {
        guard iCloudAvailable else { throw CloudKitError.iCloudNotAvailable }

        let postRef   = CKRecord.Reference(recordID: postRecordID, action: .none)
        let predicate = NSPredicate(format: "postRef == %@ AND playerID == %@", postRef, currentPlayerID)
        let query     = CKQuery(recordType: RecordType.like, predicate: predicate)

        do {
            let (likeResults, _) = try await db.records(matching: query, resultsLimit: 1)
            let existingLike     = likeResults.first.flatMap { try? $0.1.get() }

            let postRecord   = try await db.record(for: postRecordID)
            let currentCount = postRecord["likesCount"] as? Int ?? 0

            if let like = existingLike {
                // Unlike
                try await db.deleteRecord(withID: like.recordID)
                postRecord["likesCount"] = max(0, currentCount - 1) as CKRecordValue
                _ = try await db.save(postRecord)
                return (false, max(0, currentCount - 1))
            } else {
                // Like
                let likeRecord       = CKRecord(recordType: RecordType.like)
                likeRecord["postRef"]  = postRef
                likeRecord["playerID"] = currentPlayerID
                _ = try await db.save(likeRecord)
                postRecord["likesCount"] = (currentCount + 1) as CKRecordValue
                _ = try await db.save(postRecord)
                return (true, currentCount + 1)
            }
        } catch {
            throw CloudKitError.from(error)
        }
    }

    /// Retorna os recordIDs dos posts que o usuário curtiu.
    func fetchLikedPostIDs() async throws -> Set<String> {
        guard iCloudAvailable else { return [] }

        let predicate = NSPredicate(format: "playerID == %@", currentPlayerID)
        let query     = CKQuery(recordType: RecordType.like, predicate: predicate)

        do {
            let (results, _) = try await db.records(matching: query)
            return Set(results.compactMap { (_, result) -> String? in
                guard let record  = try? result.get(),
                      let postRef = record["postRef"] as? CKRecord.Reference else { return nil }
                return postRef.recordID.recordName
            })
        } catch {
            throw CloudKitError.from(error)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: - Asset Helpers (público — usado pelo PostCard)
    // ─────────────────────────────────────────────────────────────

    func downloadImage(from asset: CKAsset) throws -> UIImage {
        guard let url  = asset.fileURL,
              let data = try? Data(contentsOf: url),
              let img  = UIImage(data: data) else {
            throw CloudKitError.assetDownloadFailed
        }
        return img
    }

    func downloadVideoURL(from asset: CKAsset) throws -> URL {
        guard let url = asset.fileURL else { throw CloudKitError.assetDownloadFailed }
        let dst = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".mov")
        try FileManager.default.copyItem(at: url, to: dst)
        return dst
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: - Private Helpers
    // ─────────────────────────────────────────────────────────────

    private func fetchBondRecord(byCode code: String) async throws -> CKRecord? {
        let predicate = NSPredicate(format: "inviteCode == %@", code.uppercased())
        let query     = CKQuery(recordType: RecordType.bond, predicate: predicate)
        let (results, _) = try await db.records(matching: query, resultsLimit: 1)
        return results.first.flatMap { try? $0.1.get() }
    }

    private func checkMembership(bondRecordID: CKRecord.ID) async throws -> Bool {
        let bondRef   = CKRecord.Reference(recordID: bondRecordID, action: .none)
        let predicate = NSPredicate(format: "bondRef == %@ AND playerID == %@", bondRef, currentPlayerID)
        let query     = CKQuery(recordType: RecordType.membership, predicate: predicate)
        let (results, _) = try await db.records(matching: query, resultsLimit: 1)
        return !results.isEmpty
    }

    private func createMembership(bondRecordID: CKRecord.ID) async throws {
        let record    = CKRecord(recordType: RecordType.membership)
        record["bondRef"]    = CKRecord.Reference(recordID: bondRecordID, action: .deleteSelf)
        record["playerID"]   = currentPlayerID
        record["playerName"] = currentPlayerName
        _ = try await db.save(record)
    }

    private func encodeImageAsset(_ image: UIImage) throws -> CKAsset {
        guard let data = image.jpegData(compressionQuality: 0.75) else {
            throw CloudKitError.assetEncodingFailed
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".jpg")
        try data.write(to: url)
        return CKAsset(fileURL: url)
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: - Record → Model mapping
    // ─────────────────────────────────────────────────────────────

    private func bondFromRecord(_ record: CKRecord) throws -> BondModel {
        var bond = BondModel(name: record["name"] as? String ?? "")
        bond.recordID        = record.recordID
        bond.inviteCode      = record["inviteCode"]      as? String ?? ""
        bond.maxParticipants = record["maxParticipants"] as? Int ?? 5
        bond.memberCount     = record["memberCount"]     as? Int ?? 1
        bond.creatorID       = record["creatorID"]       as? String ?? ""

        return bond
    }

    private func postFromRecord(_ record: CKRecord) -> PostModel {
        var post = PostModel(authorName: record["authorName"] as? String ?? "")
        post.recordID      = record.recordID
        post.bondRecordID  = (record["bondRef"] as? CKRecord.Reference)?.recordID
        post.authorPlayerID = record["authorPlayerID"] as? String ?? ""
        post.caption       = record["caption"]    as? String ?? ""
        post.likes         = record["likesCount"] as? Int ?? 0
        post.timestamp     = record["timestamp"]  as? Date ?? Date()
        post.imageAsset    = record["imageAsset"] as? CKAsset
        post.videoAsset    = record["videoAsset"] as? CKAsset
        return post
    }
}
