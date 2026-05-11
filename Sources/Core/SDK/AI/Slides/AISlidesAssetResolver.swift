import Foundation

struct AISlidesAssetResolver {
    private let imageService = AISlidesImageService()
    private let cache = AISlidesCache.shared

    // MARK: - GenSlidesScheme resolution

    func resolveSchemeAssets(for scheme: GenSlidesScheme) async -> GenSlidesScheme {
        var resolved = scheme
        for slideIdx in resolved.slides.indices {
            for elemIdx in resolved.slides[slideIdx].elements.indices {
                if case .image(var ref) = resolved.slides[slideIdx].elements[elemIdx], ref.url.isEmpty {
                    if let url = await imageService.resolveImage(for: ref.query) {
                        ref.url = url.absoluteString
                        resolved.slides[slideIdx].elements[elemIdx] = .image(ref)
                        print("[AssetResolver] Resolved image for query: \(ref.query.prefix(40))")
                    }
                }
            }
        }
        return resolved
    }

    // MARK: - SlideDeck resolution

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
                    guard let url = URL(string: imageSource) else { return (slide.id, nil) }
                    let responseData: Data?
                    do {
                        let (data, response) = try await URLSession.shared.data(from: url)
                        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200
                        responseData = (200...299).contains(statusCode) ? data : nil
                    } catch {
                        responseData = nil
                    }
                    guard let data = responseData else { return (slide.id, nil) }
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
                var element = resolved.slides[index].elements[eidx]
                let query = element.caption.isEmpty ? resolved.slides[index].title : element.caption
                if element.imageURL == nil,
                   let url = await imageService.resolveImage(for: query) {
                    element.imageURL = url
                    resolved.slides[index].elements[eidx].imageURL = url
                }
            }
        }

        return resolved
    }
}
