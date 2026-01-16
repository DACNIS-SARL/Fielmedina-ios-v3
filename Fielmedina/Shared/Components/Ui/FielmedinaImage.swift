//
//  FielmedinaImage.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import SwiftUI

struct FielmedinaImage: View {
    let urlString: String?
    let contentMode: ContentMode
    
    init(url: String?, contentMode: ContentMode = .fill) {
        self.urlString = url
        self.contentMode = contentMode
    }
    
    var body: some View {
        Group {
            if let urlString = urlString, !urlString.isEmpty {
                if urlString.lowercased().hasPrefix("http") {
                    // It's a remote URL
                    AsyncImage(url: URL(string: urlString)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: contentMode)
                        case .failure:
                            fallbackImage
                        case .empty:
                            ProgressView()
                        @unknown default:
                            fallbackImage
                        }
                    }
                } else {
                    // It's a local asset
                    Image(urlString)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                }
            } else {
                fallbackImage
            }
        }
    }
    
    private var fallbackImage: some View {
        ZStack {
            Color.gray.opacity(0.3)
            Image(systemName: "photo")
                .foregroundStyle(.secondary)
        }
    }
}
