import Foundation

@available(iOS 16.0, *)
@MainActor
final class ConversionViewModel: ObservableObject {

    enum State {
        case converting
        case done(ConversionResult)
        case failed(AppError)
    }

    @Published var state:        State  = .converting
    @Published var progress:     Double = 0
    @Published var progressText: String = "Starting…"

    private let useCase = ConversionUseCase()

    func start(urlString: String) async {
        state = .converting

        useCase.onProgress = { [weak self] completed, total in
            Task { @MainActor [weak self] in
                self?.progress     = total > 0 ? Double(completed) / Double(total) : 0
                self?.progressText = "\(completed) / \(total) songs"
            }
        }

        do {
            let result = try await useCase.convert(urlString: urlString)
            state = .done(result)
        } catch let err as AppError {
            print("[ConversionViewModel] ❌ AppError: \(err.errorCode) — \(err)")
            state = .failed(err)
        } catch {
            print("[ConversionViewModel] ❌ unknown error: \(error)")
            state = .failed(.spotifyNetwork)
        }
    }
}
