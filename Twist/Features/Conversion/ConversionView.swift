import SwiftUI

@available(iOS 16.0, *)
struct ConversionView: View {
    let urlString: String

    @StateObject private var viewModel = ConversionViewModel()
    @State private var navigateToResult = false
    @State private var result: ConversionResult?

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .converting:
                convertingView
            case .done(let res):
                Color.clear
                    .onAppear {
                        result           = res
                        navigateToResult = true
                    }
            case .failed(let err):
                errorView(err)
            }
        }
        .navigationTitle("Converting")
        .navigationBarBackButtonHidden(true)
        .swipeBackEnabled()
        .task { await viewModel.start(urlString: urlString) }
        // Navigate to ResultView when done
        .background(
            NavigationLink(
                destination: ResultView(result: result ?? .empty),
                isActive: $navigateToResult
            ) { EmptyView() }
        )
    }

    // MARK: - Converting View

    private var convertingView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("Converting your playlist")
                    .font(.headline)
                Text(viewModel.progressText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: viewModel.progress)
                .padding(.horizontal, 40)
                .tint(.green)

            Spacer()

            // Ad area — reserved for Phase 6 (AdMob)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .frame(height: 60)
                .overlay(
                    Text("Ad")
                        .font(.caption)
                        .foregroundStyle(Color(.systemGray3))
                )
                .padding(.horizontal)
                .padding(.bottom)
        }
    }

    // MARK: - Error View

    private func errorView(_ error: AppError) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.red)
            Text(error.errorDescription ?? "Something went wrong.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

// MARK: - Empty placeholder

private extension ConversionResult {
    static let empty = ConversionResult(
        playlistName: "",
        totalTracks: 0,
        matchedCount: 0,
        skippedTracks: []
    )
}
