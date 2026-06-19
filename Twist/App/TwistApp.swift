import SwiftUI
import GoogleMobileAds

@main
struct TwistApp: App {
    @StateObject private var navigationState = NavigationState()

    init() {
        let requestConfig = GADMobileAds.sharedInstance().requestConfiguration
        requestConfig.tagForChildDirectedTreatment = true
        requestConfig.tagForUnderAgeOfConsent = true
        requestConfig.maxAdContentRating = GADMaxAdContentRating.general

        // AdMob SDK must be initialized before any ad is loaded
        GADMobileAds.sharedInstance().start()
    }

    var body: some Scene {
        WindowGroup {
            if #available(iOS 16.0, *) {
                HomeView()
                    .environmentObject(navigationState)
            }
        }
    }
}
