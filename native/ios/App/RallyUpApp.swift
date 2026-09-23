import CoreText
import SwiftUI

@main
struct RallyUpApp: App {
    @StateObject private var store = RallyStore()
    @StateObject private var accountSession = AccountSessionStore()

    init() {
        InterFontRegistrar.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            RallyRootView()
                .environmentObject(store)
                .environmentObject(accountSession)
                .tint(RallyTheme.darkGreen)
        }
    }
}


private enum InterFontRegistrar {
    static func registerBundledFonts() {
        for name in ["Inter-Regular", "Inter-Medium", "Inter-SemiBold", "Inter-Bold", "Inter-Black"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
