import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct BondApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

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
