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

    @State private var uiImage: UIImage?
    @State private var isLoading = false
    
    init(url: String?, contentMode: ContentMode = .fill) {
        self.urlString = url
        self.contentMode = contentMode
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

    @MainActor
    private func loadImageIfNeeded() async {
        guard let urlString = urlString,
              urlString.lowercased().hasPrefix("http"),
              let url = URL(string: urlString) else {
            uiImage = nil
            isLoading = false
            return
        }

        uiImage = nil
        isLoading = true

        let request = URLRequest(
            url: url,
            cachePolicy: .returnCacheDataElseLoad,
            timeoutInterval: 30
        )

        if let cachedResponse = URLCache.shared.cachedResponse(for: request),
           let cachedImage = UIImage(data: cachedResponse.data) {
            uiImage = cachedImage
            isLoading = false
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let image = UIImage(data: data) {
                let cachedResponse = CachedURLResponse(response: response, data: data)
                URLCache.shared.storeCachedResponse(cachedResponse, for: request)
                uiImage = image
            } else {
                uiImage = nil
            }
        } catch {
            uiImage = nil
        }

        isLoading = false
    }
}
