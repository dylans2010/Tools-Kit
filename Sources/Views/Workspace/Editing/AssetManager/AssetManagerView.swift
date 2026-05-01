import SwiftUI

struct AssetManagerView: View {
    @StateObject private var manager = AssetManager.shared
    @State private var query = ""

    var body: some View {
        VStack {
            SearchBar(text: $query)
                .padding()

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                    ForEach(manager.library.filter { query.isEmpty || $0.name.contains(query) }) { asset in
                        AssetThumbnail(asset: asset)
                    }

                    // Mock assets if empty
                    if manager.library.isEmpty {
                        AssetThumbnail(asset: MediaAsset(id: UUID(), name: "Drone Shot 01", type: .video, tags: ["nature"], size: 1024, duration: 15))
                        AssetThumbnail(asset: MediaAsset(id: UUID(), name: "Background Loop", type: .video, tags: ["ambient"], size: 2048, duration: 30))
                        AssetThumbnail(asset: MediaAsset(id: UUID(), name: "Logo Overlay", type: .image, tags: ["brand"], size: 512, duration: nil))
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Asset Library")
    }
}

struct AssetThumbnail: View {
    let asset: MediaAsset

    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 100)

                Image(systemName: iconName)
                    .padding(6)
                    .foregroundColor(.white)
            }

            Text(asset.name)
                .font(.caption)
                .lineLimit(1)
        }
    }

    private var iconName: String {
        switch asset.type {
        case .image: return "photo"
        case .video: return "video.fill"
        case .audio: return "waveform"
        case .overlay: return "square.on.square"
        }
    }
}
