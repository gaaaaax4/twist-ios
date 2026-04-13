import SwiftUI

@available(iOS 16.0, *)
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var navigationState: NavigationState

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()

                // Logo area
                VStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 72))
                        .foregroundStyle(.green)
                    Text("Twist")
                        .font(.largeTitle.bold())
                }

                // Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Paste a Spotify playlist link")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        if let str = UIPasteboard.general.string {
                            viewModel.urlText = str
                        }
                    } label: {
                        HStack {
                            Image(systemName: viewModel.urlText.isEmpty ? "doc.on.clipboard" : "checkmark.circle.fill")
                                .foregroundStyle(viewModel.urlText.isEmpty ? Color.secondary : Color.green)
                            Text(viewModel.urlText.isEmpty ? "Tap to paste" : "Link ready")
                                .foregroundStyle(viewModel.urlText.isEmpty ? .secondary : .primary)
                            Spacer()
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal)

                // Convert button + navigation
                NavigationLink(
                    destination: ConversionView(urlString: viewModel.urlText),
                    isActive: $viewModel.isConverting
                ) {
                    Button {
                        viewModel.startConversion()
                    } label: {
                        Label("Convert", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isValidURL ? Color.green : Color.secondary.opacity(0.4))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!viewModel.isValidURL)
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        // Reset navigation stack to root when signalled (e.g. from ResultView)
        .id(navigationState.root)
        .onReceive(navigationState.$root) { _ in
            viewModel.isConverting = false
        }
    }
}
