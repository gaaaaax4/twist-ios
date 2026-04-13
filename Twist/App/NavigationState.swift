import Foundation

/// Shared navigation state. Changing `root` resets the navigation stack.
final class NavigationState: ObservableObject {
    @Published var root = UUID()

    func popToRoot() {
        root = UUID()
    }
}
