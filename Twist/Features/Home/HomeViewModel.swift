import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var urlText:       String = ""
    @Published var isConverting:  Bool   = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Handle deep links from the OS (twist://convert?url=...)
        NotificationCenter.default.publisher(for: .conversionRequested)
            .compactMap { $0.userInfo?["url"] as? String }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] urlString in
                self?.urlText      = urlString
                self?.isConverting = true
            }
            .store(in: &cancellables)
    }

    var isValidURL: Bool {
        let t = urlText.trimmingCharacters(in: .whitespaces)
        return t.contains("open.spotify.com/playlist/") ||
               t.hasPrefix("spotify:playlist:")
    }

    func startConversion() {
        isConverting = true
    }
}
