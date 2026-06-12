import Foundation
import UIKit

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var selectedImage:   UIImage? = nil
    @Published var conversionImage: UIImage? = nil
    @Published var playlistName:    String   = ""
    @Published var isConverting:    Bool     = false

    var isReady: Bool { selectedImage != nil }

    func startConversion() {
        conversionImage = selectedImage
        isConverting    = true
    }
}
