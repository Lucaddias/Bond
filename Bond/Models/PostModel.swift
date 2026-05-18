// PostModel.swift
// Bond

import SwiftUI
import CloudKit

struct PostModel: Identifiable {
    let id: UUID = UUID()
    var authorName: String
    var authorPhoto: UIImage?

    // ── Mídia local (antes de publicar / após download) ──────────
    var image: UIImage?
    var videoURL: URL?

    // ── Mídia remota (referência CloudKit para download lazy) ────
    var imageAsset: CKAsset? = nil
    var videoAsset: CKAsset? = nil

    var caption: String = ""
    var likes: Int = 0
    var isLiked: Bool = false
    var timestamp: Date = Date()

    // ── Campos CloudKit ──────────────────────────────────────────
    var recordID: CKRecord.ID? = nil
    var bondRecordID: CKRecord.ID? = nil
    var authorPlayerID: String = ""

    var hasVideo: Bool { videoURL != nil || videoAsset != nil }
    var hasMedia: Bool { image != nil || videoURL != nil || imageAsset != nil || videoAsset != nil }
}
