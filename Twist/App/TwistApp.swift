import SwiftUI

@main
struct TwistApp: App {
    @StateObject private var navigationState = NavigationState()

    var body: some Scene {
        WindowGroup {
            if #available(iOS 16.0, *) {
                HomeView()
                    .environmentObject(navigationState)
                    .onOpenURL { url in
                        handleDeepLink(url: url)
                    }
            }
        }
    }

    private func handleDeepLink(url: URL) {
        // Handles: twist://convert?url={encoded_spotify_url}
        guard
            url.scheme == "twist",
            url.host == "convert",
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let spotifyURL = components.queryItems?.first(where: { $0.name == "url" })?.value
        else { return }

        NotificationCenter.default.post(
            name: .conversionRequested,
            object: nil,
            userInfo: ["url": spotifyURL]
        )
    }
}

extension Notification.Name {
    static let conversionRequested = Notification.Name("twist.conversionRequested")
}
