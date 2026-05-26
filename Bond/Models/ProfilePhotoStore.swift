// ProfilePhotoStore.swift
// Bond

import UIKit

enum ProfilePhotoStore {
    private static var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile_photo.jpg")
    }

    static func save(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)
        }
    }

    static func load() -> UIImage? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    static func delete() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    static func saveName(_ name: String) {
        UserDefaults.standard.set(name, forKey: "profile_name")
    }

    static func loadName() -> String? {
        UserDefaults.standard.string(forKey: "profile_name")
    }

    static func saveAboutMe(_ text: String) {
        UserDefaults.standard.set(text, forKey: "profile_about_me")
    }

    static func loadAboutMe() -> String {
        UserDefaults.standard.string(forKey: "profile_about_me") ?? ""
    }
}
