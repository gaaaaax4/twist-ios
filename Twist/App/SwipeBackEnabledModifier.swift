import SwiftUI
import UIKit

/// Re-enables the swipe-back (interactive pop) gesture even when
/// the navigation back button is hidden.
struct SwipeBackEnabledModifier: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ vc: UIViewController, context: Context) {
        DispatchQueue.main.async {
            vc.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            vc.navigationController?.interactivePopGestureRecognizer?.delegate  = nil
        }
    }
}

extension View {
    /// Call this on any view that hides the back button but still wants swipe-back.
    func swipeBackEnabled() -> some View {
        background(SwipeBackEnabledModifier())
    }
}
