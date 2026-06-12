import SwiftUI

@available(iOS 16.0, *)
struct ConversionView: View {
    let image:        UIImage
    let playlistName: String

    @StateObject private var viewModel = ConversionViewModel()
    @EnvironmentObject private var navigationState: NavigationState
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
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .swipeBackEnabled()
        .task { await viewModel.start(image: image, playlistName: playlistName) }
        .navigationDestination(isPresented: $navigateToResult) {
            ResultView(result: result ?? .empty)
        }
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

            // Banner Ad
            BannerAdView()
                .frame(height: 60)
                .padding(.horizontal, 16)
                .padding(.bottom)
        }
    }

    // MARK: - Error View

    private func errorView(_ error: AppError) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.red)
            Text(error.errorDescription ?? "Something went wrong.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            Button {
                navigationState.popToRoot()
            } label: {
                Label("Home", systemImage: "house")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}
