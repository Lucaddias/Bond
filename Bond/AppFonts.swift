import SwiftUI
import UIKit
import CoreText

/// Centralized helper for registering and using bundled custom fonts.
enum FontRegistrar {
    /// Register all fonts that are shipped in the app bundle.
    /// Call this early at app launch.
    static func registerAllFonts() {
        // Busca por todas as variações de extensão (case-sensitive no iOS)
        let extensions = ["ttf", "TTF", "otf", "OTF"]
        for ext in extensions {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                for url in urls {
                    registerFont(at: url)
                }
            }
        }
    }

    /// Register a font at a direct file URL.
    private static func registerFont(at url: URL) {
        var error: Unmanaged<CFError>?
        let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        if !success {
            if let err = error?.takeRetainedValue() {
                #if DEBUG
                print("[FontRegistrar] Failed to register font at URL \(url): \(err)")
                #endif
            } else {
                #if DEBUG
                print("[FontRegistrar] Failed to register font at URL \(url) with unknown error")
                #endif
            }
        }
    }

    /// Registers a single font at the provided relative bundle path if possible.
    private static func registerFontIfNeeded(relativePath: String) {
        guard let url = Bundle.main.url(forResource: relativePath, withExtension: nil) else {
            #if DEBUG
            print("[FontRegistrar] Missing font at path: \(relativePath)")
            #endif
            return
        }
        registerFont(at: url)
    }

    /// Prints all registered fonts to help you find the correct PostScript names.
    static func debugPrintRegisteredFonts() {
        for family in UIFont.familyNames.sorted() {
            print("[FontRegistrar] Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family).sorted() {
                print("    - \(name)")
            }
        }
    }
}

/// Convenience API for using your app's custom fonts in SwiftUI.
/// Update the raw values to match the PostScript names printed by `debugPrintRegisteredFonts()`.
public enum AppFont: String {
    // Baloo Bhaina 2 — replace with exact PostScript names if they differ.
    case balooRegular = "BalooBhaina2-Regular"
    case balooMedium  = "BalooBhaina2-Medium"
    case balooBold    = "BalooBhaina2-Bold"

    // Porkys — the PostScript names may differ from file names; adjust after debugging print.
    case porkysRegular = "Porkys"
    case porkysHeavy = "PorkysHeavy"
}

public extension Font {
    /// Create a Font using one of the app's custom fonts with a fixed size.
    static func app(_ font: AppFont, size: CGFloat) -> Font {
        .custom(font.rawValue, size: size)
    }

    /// Create a Font using one of the app's custom fonts, participating in Dynamic Type.
    static func app(_ font: AppFont, size: CGFloat, relativeTo textStyle: TextStyle) -> Font {
        .custom(font.rawValue, size: size, relativeTo: textStyle)
    }
}
