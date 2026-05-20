import SwiftUI

@main
struct BondApp: App {

    init() {
        FontRegistrar.registerAllFonts()
        #if DEBUG
        FontRegistrar.debugPrintRegisteredFonts()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
