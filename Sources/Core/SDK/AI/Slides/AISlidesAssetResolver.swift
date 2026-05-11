import Foundation

struct AISlidesAssetResolver {
    private let imageService = AISlidesImageService()
    private let cache = AISlidesCache.shared

    func resolveAssets(for deck: SlideDeck) async -> SlideDeck {
        var resolved = deck

        await withTaskGroup(of: (UUID, Data?).self) { group in
            for slide in deck.slides {
                group.addTask {
                    let imageSource = slide.elements.first(where: { $0.kind == .image })?.imageURL?.absoluteString
                    guard let imageSource else { return (slide.id, nil) }
                    let key = "img_data_\(AISlidesCache.hash(imageSource))"
                    if let cached = await cache.cachedImageData(for: key) {
                        return (slide.id, cached)
                    }
                    guard let url = URL(string: imageSource),
                          let data = try? Data(contentsOf: url) else { return (slide.id, nil) }
                    await cache.storeImageData(data, for: key)
                    return (slide.id, data)
                }
            }

            for await (slideID, data) in group {
                guard let data,
                      let index = resolved.slides.firstIndex(where: { $0.id == slideID }) else { continue }
                resolved.slides[index].backgroundImageData = data
            }
        }

        for index in resolved.slides.indices {
            for eidx in resolved.slides[index].elements.indices where resolved.slides[index].elements[eidx].kind == .image {
                if resolved.slides[index].elements[eidx].imageURL == nil,
                   let caption = resolved.slides[index].elements[eidx].caption.isEmpty ? nil : resolved.slides[index].elements[eidx].caption,
                   let url = await imageService.resolveImage(for: caption ?? resolved.slides[index].title) {
                    resolved.slides[index].elements[eidx].imageURL = url
                }
            }
        }

        return resolved
    }
}
