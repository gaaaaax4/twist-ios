import SwiftUI
import GoogleMobileAds

// MARK: - Ad Unit ID Config
// Replace with your real Ad Unit ID from AdMob dashboard before release.
// Test ID is safe during development.
enum AdConfig {
    static let bannerAdUnitID = "ca-app-pub-5093550276623040/4718279675"
}

// MARK: - SwiftUI Banner Ad View

struct BannerAdView: UIViewRepresentable {

    func makeUIView(context: Context) -> GADBannerView {
        let adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(
            UIScreen.main.bounds.width - 32
        )
        let banner = GADBannerView(adSize: adSize)
        banner.adUnitID = AdConfig.bannerAdUnitID
        banner.rootViewController = topViewController()
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}

    // MARK: - Helpers

    private func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow })
        else { return nil }
        return window.rootViewController
    }
}
