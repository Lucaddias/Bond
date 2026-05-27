import SwiftUI

@main
struct BondApp: App {

    @State private var showLoading = true

    init() {
        FontRegistrar.registerAllFonts()
        #if DEBUG
        FontRegistrar.debugPrintRegisteredFonts()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // ContentView está SEMPRE no stack — o .task dela começa a
                // buscar dados do CloudKit enquanto o vídeo de loading toca.
                // Quando o loading some, os dados já estão (ou quase estão) prontos.
                ContentView()

                // Loading fica por cima com opacity; quando showLoading = false
                // faz fade-out e para de bloquear toques.
                LoadingView(onFinished: {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showLoading = false
                    }
                })
                .opacity(showLoading ? 1 : 0)
                .allowsHitTesting(showLoading)
            }
        }
    }
}



