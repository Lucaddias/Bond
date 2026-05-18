import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        // Registra para push notifications silenciosas (CloudKit subscriptions)
        application.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // CloudKit entregará silent pushes quando houver novos posts
        // A ContentView escuta via .task e o FeedView faz refresh onAppear
        completionHandler(.newData)
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
                .task {
                    // Setup CloudKit assim que o app abre
                    await CloudKitManager.shared.setup()
                }
        }
    }
}
