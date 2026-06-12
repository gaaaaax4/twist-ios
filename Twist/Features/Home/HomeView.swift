import SwiftUI
import PhotosUI

@available(iOS 16.0, *)
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var navigationState: NavigationState

    @State private var pickerItem: PhotosPickerItem? = nil

    var body: some View {
        NavigationStack {
            let selectedImg = viewModel.selectedImage
            
            VStack(spacing: 28) {
                Spacer()

                // Image picker
                PhotosPicker(
                    selection: $pickerItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    ZStack {
                        if let img = selectedImg {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                            VStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.secondary)
                                Text("Tap to select screenshot")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .onChange(of: pickerItem) { newItem in
                    Task {
                        guard let newItem = newItem else { return }
                        let data = try? await newItem.loadTransferable(type: Data.self)
                        guard let data = data,
                              let img = UIImage(data: data)
                        else { return }
                        let preview = img.preparingThumbnail(of: CGSize(width: 600, height: 1200)) ?? img
                        await MainActor.run { viewModel.selectedImage = preview }
                    }
                }

                // Playlist name
                VStack(alignment: .leading, spacing: 6) {
                    Text("Playlist name (optional)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField("Converted Playlist", text: $viewModel.playlistName)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal)

                // Convert button
                Button {
                    viewModel.startConversion()
                } label: {
                    Label("Twist!", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isReady ? Color.green : Color.secondary.opacity(0.4))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!viewModel.isReady)
                .padding(.horizontal)

                Spacer()

                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-")")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 8)
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $viewModel.isConverting) {
                if let img = viewModel.conversionImage {
                    ConversionView(image: img, playlistName: viewModel.playlistName)
                }
            }
        }
        .id(navigationState.root)
        .onReceive(navigationState.$root) { _ in
            viewModel.isConverting  = false
            viewModel.selectedImage = nil
            viewModel.playlistName  = ""
            pickerItem              = nil
        }
    }
}
