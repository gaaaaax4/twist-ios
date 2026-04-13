import SwiftUI

@available(iOS 16.0, *)
struct ResultView: View {
    let result: ConversionResult

    // Pop all the way back to HomeView
    @EnvironmentObject private var navigationState: NavigationState

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {

                // Header
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.green)
                    Text("Done!")
                        .font(.largeTitle.bold())
                    Text("\"\(result.playlistName)\"")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Stats
                HStack(spacing: 48) {
                    statView(count: result.matchedCount,           label: "Added")
                    statView(count: result.skippedTracks.count,    label: "Skipped")
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Skipped list
                if !result.skippedTracks.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Songs not found on Apple Music")
                            .font(.headline)
                            .padding(.bottom, 2)

                        ForEach(result.skippedTracks, id: \.self) { track in
                            HStack(spacing: 8) {
                                Image(systemName: "questionmark.circle")
                                    .foregroundStyle(.orange)
                                Text(track)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Back button
                Button {
                    navigationState.popToRoot()
                } label: {
                    Label("Back to Home", systemImage: "house")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Result")
        .navigationBarBackButtonHidden(true)
    }

    private func statView(count: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
