import SwiftUI

@available(iOS 16.0, *)
struct ResultView: View {
    let result: ConversionResult

    @EnvironmentObject private var navigationState: NavigationState
    @State private var showRawOCR = false

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
                    statView(count: result.matchedCount,        label: "Added")
                    statView(count: result.skippedTracks.count, label: "Skipped")
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // OCR recognized tracks
                if !result.recognizedTracks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("OCR認識結果 (\(result.recognizedTracks.count)曲)")
                            .font(.headline)
                            .padding(.bottom, 2)
                        ForEach(Array(result.recognizedTracks.enumerated()), id: \.offset) { _, track in
                            let key     = "\(track.name) – \(track.artist)"
                            let matched = !result.skippedTracks.contains(key)
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: matched ? "checkmark.circle.fill" : "questionmark.circle")
                                    .foregroundStyle(matched ? .green : .orange)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(track.name).font(.subheadline)
                                    Text(track.artist).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Raw OCR lines (debug)
                if !result.rawOCRLines.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Button {
                            showRawOCR.toggle()
                        } label: {
                            HStack {
                                Text("生 OCRログ (\(result.rawOCRLines.count)行)")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: showRawOCR ? "chevron.up" : "chevron.down")
                            }
                            .foregroundStyle(.primary)
                            .padding()
                        }
                        if showRawOCR {
                            Divider()
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(result.rawOCRLines.enumerated()), id: \.offset) { i, line in
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("\(i + 1)")
                                            .font(.system(.caption2, design: .monospaced))
                                            .foregroundStyle(.tertiary)
                                            .frame(width: 24, alignment: .trailing)
                                        Text(line)
                                            .font(.system(.caption, design: .monospaced))
                                    }
                                }
                            }
                            .padding()
                        }
                    }
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
