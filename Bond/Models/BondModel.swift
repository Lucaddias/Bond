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
}
