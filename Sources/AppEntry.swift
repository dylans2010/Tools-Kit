import SwiftUI
import Appwrite
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        SDKLogStore.shared.log("LM Link: [SCENE] SceneDelegate received URL: \(url.absoluteString)", source: "SceneDelegate", level: .info)
        LMLinkLogger.deeplink.info("SceneDelegate received URL: \(url.absoluteString, privacy: .private(mask: .hash))")
        Task { @MainActor in
            AppDeepLinkRouter.shared.handle(url)
        }
    }
}

@main
struct ToolsKitApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .registerOAuthHandler()
                .onOpenURL { url in
                    SDKLogStore.shared.log("LM Link: [SWIFTUI] onOpenURL received URL: \(url.absoluteString)", source: "ToolsKitApp", level: .info)
                    LMLinkLogger.deeplink.info("SwiftUI .onOpenURL received URL: \(url.absoluteString, privacy: .private(mask: .hash))")
                    AppDeepLinkRouter.shared.handle(url)
                }
                .task {
                    await LMLinkAuthManager.shared.restoreSession()
                }
        }
    }
}
