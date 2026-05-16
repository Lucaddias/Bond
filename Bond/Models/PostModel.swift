// PostModel.swift
// Bond

import SwiftUI

struct PostModel: Identifiable {
    let id: UUID = UUID()
    var authorName: String
    var authorPhoto: UIImage?
    var image: UIImage?
    var videoURL: URL?
    var caption: String = ""
    var likes: Int = 0
    var isLiked: Bool = false
    var timestamp: Date = Date()

    var hasVideo: Bool { videoURL != nil }
}
