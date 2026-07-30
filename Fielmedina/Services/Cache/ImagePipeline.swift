//
//  ImagePipeline.swift
//  Fielmedina
//
//  Shared image loading pipeline. Three things matter for scroll performance and
//  memory, and all three happen here instead of in the view:
//
//  1. Decoding is DOWNSAMPLED to the size actually displayed. A 3000x2000 photo
//     decodes to ~24 MB of pixels; capped to 1600px it's ~5 MB, and a 44pt
//     thumbnail needs ~0.2 MB. Without this, thumbnails cost as much as heroes.
//  2. Disk reads, network and decoding run OFF the main thread. Previously all of
//     it (URLCache lookup, Data(contentsOf:), UIImage(data:), cache writes) ran on
//     the main actor, which stalls scrolling.
//  3. Decoded images are cached in memory, so scrolling away and back is instant
//     instead of re-reading and re-decoding from disk every time.
//

import UIKit
import ImageIO

enum ImagePipeline {
    /// Cache of *decoded* images, keyed by URL + decode size. Cost is in bytes so
    /// the limit reflects real pixel memory, and NSCache evicts under pressure.
    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 96 * 1024 * 1024 // ~96 MB of decoded pixels
        return cache
    }()

    /// Default decode cap — generous enough for a full-width image on any phone,
    /// but never the full camera-resolution original.
    static let defaultMaxPixelSize: CGFloat = 1600

    private static func key(_ url: URL, _ maxPixelSize: CGFloat) -> NSString {
        "\(url.absoluteString)#\(Int(maxPixelSize))" as NSString
    }

    /// Synchronous memory-cache lookup. Lets a view show a cached image on the
    /// first render with no async hop and no placeholder flicker.
    static func cachedImage(for url: URL, maxPixelSize: CGFloat) -> UIImage? {
        cache.object(forKey: key(url, maxPixelSize))
    }

    /// Full load: memory cache → URLCache → durable disk cache → network.
    /// Everything except the memory-cache probe runs off the main thread.
    static func image(for url: URL, maxPixelSize: CGFloat) async -> UIImage? {
        if let hit = cachedImage(for: url, maxPixelSize: maxPixelSize) { return hit }

        return await Task.detached(priority: .userInitiated) { () -> UIImage? in
            let request = URLRequest(
                url: url,
                cachePolicy: .returnCacheDataElseLoad,
                timeoutInterval: 30
            )

            // 1) URLCache (fast path; already-fetched bytes)
            if let cached = URLCache.shared.cachedResponse(for: request),
               let image = decode(data: cached.data, maxPixelSize: maxPixelSize) {
                store(image, for: url, maxPixelSize: maxPixelSize)
                return image
            }

            // 2) Durable cache — survives iOS purging the Caches directory, so
            //    offline content keeps rendering.
            if let data = MediaDiskCache.cachedData(forRemote: url),
               let image = decode(data: data, maxPixelSize: maxPixelSize) {
                store(image, for: url, maxPixelSize: maxPixelSize)
                return image
            }

            // 3) Network, then persist to both cache tiers.
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let image = decode(data: data, maxPixelSize: maxPixelSize) else { return nil }
                URLCache.shared.storeCachedResponse(
                    CachedURLResponse(response: response, data: data),
                    for: request
                )
                MediaDiskCache.store(data, forRemote: url)
                store(image, for: url, maxPixelSize: maxPixelSize)
                return image
            } catch {
                return nil
            }
        }.value
    }

    private static func store(_ image: UIImage, for url: URL, maxPixelSize: CGFloat) {
        let cost: Int
        if let cg = image.cgImage {
            cost = cg.bytesPerRow * cg.height
        } else {
            cost = Int(image.size.width * image.size.height * 4)
        }
        cache.setObject(image, forKey: key(url, maxPixelSize), cost: cost)
    }

    /// Decodes at a reduced size using ImageIO, which never materializes the
    /// full-resolution bitmap. `shouldCacheImmediately` forces the decode to happen
    /// here (background) rather than lazily on the main thread at first draw.
    private static func decode(data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
            return nil
        }
        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
            source, 0, thumbnailOptions as CFDictionary
        ) else {
            // Fall back to a normal decode for formats ImageIO can't thumbnail.
            return UIImage(data: data)
        }
        return UIImage(cgImage: cgImage)
    }
}
