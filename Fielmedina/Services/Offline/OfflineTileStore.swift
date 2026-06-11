//
//  OfflineTileStore.swift
//  Fielmedina
//
//  Created by Aslan on 11/6/2026.
//

import Foundation
import MapboxCommon
import MapboxMaps

enum OfflineTileStore {
    private static let tilesURL: URL = {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let url = base.appendingPathComponent("mapbox-tiles", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    /// Resolved AFTER configure() sets dataPath, so TileStore.default points here.
    static var shared: TileStore {
        TileStore.default
    }

    /// MUST be the first Mapbox-related call at launch.
    static func configure() {
        MapboxMapsOptions.dataPath = tilesURL
    }
}

