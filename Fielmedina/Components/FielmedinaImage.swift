//
//  FielmedinaImage.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import SwiftUI
import UIKit

struct FielmedinaImage: View {
    let urlString: String?
    let contentMode: ContentMode
    /// Largest pixel dimension to decode to. Pass a small value for thumbnails so a
    /// 44pt avatar doesn't decode a full-resolution photo into memory. Defaults to a
    /// full-screen-sized cap.
    let maxPixelSize: CGFloat

    @State private var uiImage: UIImage?
    @State private var isLoading = false

    init(url: String?, contentMode: ContentMode = .fill, maxPixelSize: CGFloat? = nil) {
        self.urlString = url
        self.contentMode = contentMode
        self.maxPixelSize = maxPixelSize ?? ImagePipeline.defaultMaxPixelSize
    }

    var body: some View {
        Group {
            if let urlString = urlString, !urlString.isEmpty {
                if urlString.lowercased().hasPrefix("http") {
                    if let uiImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                    } else if isLoading {
                        ProgressView()
                    } else {
                        fallbackImage
                    }
                } else {
                    Image(urlString)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                }
            } else {
                fallbackImage
            }
        }
        .task(id: urlString) {
            await loadImageIfNeeded()
        }
    }

    private var fallbackImage: some View {
        ZStack {
            Color.gray.opacity(0.3)
            Image(systemName: "photo")
                .foregroundStyle(.secondary)
        }
    }

    private func loadImageIfNeeded() async {
        guard let urlString = urlString,
              urlString.lowercased().hasPrefix("http"),
              let url = URL(string: urlString) else {
            uiImage = nil
            isLoading = false
            return
        }

        // Already decoded and in memory: show it immediately. Keeps scrolling back
        // through a list instant and avoids a placeholder flash.
        if let cached = ImagePipeline.cachedImage(for: url, maxPixelSize: maxPixelSize) {
            uiImage = cached
            isLoading = false
            return
        }

        uiImage = nil
        isLoading = true

        // Disk I/O, network and decoding all happen off the main thread inside the
        // pipeline; only this assignment lands back here.
        let loaded = await ImagePipeline.image(for: url, maxPixelSize: maxPixelSize)

        // The view may have been recycled onto a different URL while we loaded.
        guard urlString == self.urlString else { return }

        uiImage = loaded
        isLoading = false
    }
}
