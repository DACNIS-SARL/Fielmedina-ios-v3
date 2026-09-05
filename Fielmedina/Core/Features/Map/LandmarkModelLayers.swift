//
//  LandmarkModelLayers.swift
//  Fielmedina
//
//  Renders landmark `.glb` models on the map with Mapbox's `ModelLayer`, and clears
//  the default 3D building underneath each one with a `ClipLayer`.
//
//  ## Why this shape
//
//  The Mapbox GL JS examples for this use Threebox, a browser-only library with no
//  mobile equivalent. The mobile SDKs solve it natively instead:
//   - `addStyleModel(modelId:modelUri:)` registers a glTF asset with the style
//   - `ModelLayer` draws it at the coordinates of a GeoJSON feature
//   - `ClipLayer` removes Mapbox's own extruded building so the two don't z-fight
//
//  ## Offline
//
//  Model URIs are always `file://` paths from `ModelDiskCache` — never the remote
//  URL. A landmark whose model hasn't been prefetched yet is simply skipped and keeps
//  its normal marker, which is the correct behaviour inside a medina with no signal.
//
//  ## Experimental API
//
//  `addStyleModel` is `@_spi(Experimental)` in MapboxMaps 11.28. It works, but Mapbox
//  may change it in a minor release without calling it a breaking change. Everything
//  here is deliberately funnelled through this one file so an SDK change has exactly
//  one place to land.
//

import Foundation
import CoreLocation
@_spi(Experimental) import MapboxMaps

enum LandmarkModelLayers {

    /// A landmark that is ready to render: model already on disk, transform resolved.
    struct Placement {
        let locationId: String
        let modelFileURL: URL
        let coordinate: CLLocationCoordinate2D
        let scale: Double
        let rotation: Double
        let altitude: Double
    }

    private static let sourceId = "fielmedina-landmark-models-source"
    private static let clipSourceId = "fielmedina-landmark-clip-source"
    private static let modelLayerId = "fielmedina-landmark-models-layer"
    private static let clipLayerId = "fielmedina-landmark-models-clip"
    private static let modelIdPrefix = "fielmedina-model-"

    /// Half-width of the square footprint cleared under each model, in metres.
    /// Large enough to swallow the generic building Mapbox draws for a medina
    /// landmark, small enough not to punch a hole through its neighbours.
    private static let clipHalfWidthMeters = 40.0

    /// Ids currently registered with the style, so a refresh can retire stale ones.
    private static var registeredModelIds: Set<String> = []
    /// Model layer ids currently on the map, one per landmark.
    private static var addedLayerIds: Set<String> = []

    /// Builds the renderable set from the loaded locations.
    ///
    /// Filters out everything that isn't ready — no model URL, or the file hasn't been
    /// prefetched. Returning a value type keeps the decision testable and keeps
    /// filesystem checks off the rendering path.
    static func placements(from locations: [Location]) -> [Placement] {
        locations.compactMap { location in
            guard location.hasModel3d,
                  let remote = location.model3d,
                  let localURL = ModelDiskCache.cachedFileURL(forRemoteString: remote) else {
                return nil
            }
            return Placement(
                locationId: location.id,
                modelFileURL: localURL,
                coordinate: CLLocationCoordinate2D(
                    latitude: location.latitude,
                    longitude: location.longitude
                ),
                // Backend defaults are 1.0/0.0/0.0; `??` only covers a null column on
                // a row written before the migration.
                scale: location.modelScale ?? 1.0,
                rotation: location.modelRotation ?? 0.0,
                altitude: location.modelAltitude ?? 0.0
            )
        }
    }

    /// Installs (or refreshes) the model + clip layers on `mapboxMap`.
    ///
    /// Safe to call repeatedly: it replaces the source data and re-registers models,
    /// so it can be driven straight from the locations list changing.
    @MainActor
    static func apply(placements: [Placement], to mapboxMap: MapboxMap) {
        guard !placements.isEmpty else {
            removeAll(from: mapboxMap)
            return
        }

        // 1. Register each .glb with the style under a stable id.
        var liveModelIds = Set<String>()
        for placement in placements {
            let modelId = modelIdPrefix + placement.locationId
            liveModelIds.insert(modelId)
            guard !registeredModelIds.contains(modelId) else { continue }
            do {
                try mapboxMap.addStyleModel(
                    modelId: modelId,
                    modelUri: placement.modelFileURL.absoluteString
                )
                registeredModelIds.insert(modelId)
            } catch {
                LogUtils.e("LandmarkModelLayers", "Failed to register model \(modelId)", error)
            }
        }

        // Retire models for landmarks that are no longer displayed, so the renderer
        // isn't holding glTF buffers for things that left the list.
        for staleId in registeredModelIds.subtracting(liveModelIds) {
            try? mapboxMap.removeStyleModel(modelId: staleId)
            registeredModelIds.remove(staleId)
        }

        // 2. One GeoJSON feature per landmark. All features share a single source;
        //    each layer below filters down to its own by `location-id`.
        let features: [Feature] = placements.map { placement in
            var feature = Feature(geometry: Point(placement.coordinate))
            feature.identifier = .string(placement.locationId)
            feature.properties = ["location-id": .string(placement.locationId)]
            return feature
        }

        do {
            if mapboxMap.sourceExists(withId: sourceId) {
                mapboxMap.updateGeoJSONSource(
                    withId: sourceId,
                    geoJSON: .featureCollection(FeatureCollection(features: features))
                )
            } else {
                var source = GeoJSONSource(id: sourceId)
                source.data = .featureCollection(FeatureCollection(features: features))
                try mapboxMap.addSource(source)
            }
        } catch {
            LogUtils.e("LandmarkModelLayers", "Failed to add model source", error)
            return
        }

        // 3. One ModelLayer per landmark, each with constant transforms.
        //
        //    A single data-driven layer reading scale/rotation from feature properties
        //    is NOT possible here: Mapbox's `array` expression is a type *assertion*
        //    (`["array", type, N, value]`), not a constructor, so there's no way to
        //    build the 3-element vectors these properties need from `get` calls. The
        //    renderer rejects it with "The item type argument of array must be one of
        //    string, number, boolean".
        //
        //    Per-landmark layers are fine in practice — only hero buildings get a
        //    model, so this is a handful of layers, not one per catalogue row.
        var liveLayerIds = Set<String>()
        for placement in placements {
            let layerId = modelLayerId + "-" + placement.locationId
            liveLayerIds.insert(layerId)
            guard !mapboxMap.layerExists(withId: layerId) else { continue }

            var layer = ModelLayer(id: layerId, source: sourceId)
            layer.filter = Exp(.eq) {
                Exp(.get) { "location-id" }
                placement.locationId
            }
            layer.modelId = .constant(modelIdPrefix + placement.locationId)
            layer.modelType = .constant(.common3d)
            layer.modelScale = .constant([placement.scale, placement.scale, placement.scale])
            // Mapbox takes rotation as [x, y, z] degrees; heading is the z axis.
            layer.modelRotation = .constant([0, 0, placement.rotation])
            layer.modelTranslation = .constant([0, 0, placement.altitude])
            // Standard style is slot-based. `middle` puts the model above the ground
            // and basemap fills but below labels, which is what a building wants.
            // If a real model ends up hidden behind Mapbox's own 3D content, this is
            // the first thing to try changing (`.top`).
            layer.slot = .middle
            do {
                try mapboxMap.addLayer(layer)
            } catch {
                LogUtils.e("LandmarkModelLayers", "Failed to add model layer \(layerId)", error)
            }
        }

        // Drop layers for landmarks no longer displayed.
        for staleLayerId in addedLayerIds.subtracting(liveLayerIds) {
            try? mapboxMap.removeLayer(withId: staleLayerId)
        }
        addedLayerIds = liveLayerIds

        // 4. Clip Mapbox's own extruded buildings where ours stand — the mobile
        //    equivalent of the clip-layer-building GL JS example. Without it a custom
        //    mosque sits inside the generic grey block Mapbox already draws.
        //
        //    This needs its OWN source: a clip layer only accepts **polygon**
        //    geometry. Pointing it at the model layer's point source makes the
        //    renderer log "ClipBucket: adding non-polygon geometry (Point)" and clip
        //    nothing.
        let clipFeatures: [Feature] = placements.map { placement in
            Feature(geometry: .polygon(squareFootprint(
                around: placement.coordinate,
                halfWidthMeters: clipHalfWidthMeters
            )))
        }

        do {
            LogUtils.d("LandmarkModelLayers", "Applied \(placements.count) model placement(s)")

            if mapboxMap.sourceExists(withId: clipSourceId) {
                mapboxMap.updateGeoJSONSource(
                    withId: clipSourceId,
                    geoJSON: .featureCollection(FeatureCollection(features: clipFeatures))
                )
            } else {
                var clipSource = GeoJSONSource(id: clipSourceId)
                clipSource.data = .featureCollection(FeatureCollection(features: clipFeatures))
                try mapboxMap.addSource(clipSource)
            }
        } catch {
            LogUtils.e("LandmarkModelLayers", "Failed to add clip source", error)
            return
        }

        if !mapboxMap.layerExists(withId: clipLayerId) {
            var clip = ClipLayer(id: clipLayerId, source: clipSourceId)
            // Clip the basemap's own 3D models (its generic buildings). Symbols are
            // deliberately left alone — clipping them would also erase the street and
            // POI labels around the landmark.
            clip.clipLayerTypes = .constant([.model])
            do {
                try mapboxMap.addLayer(clip)
            } catch {
                LogUtils.e("LandmarkModelLayers", "Failed to add clip layer", error)
            }
        }
    }

    /// Square polygon of `halfWidthMeters` around a coordinate.
    ///
    /// Longitude degrees shrink with latitude, so the east/west offset is divided by
    /// cos(latitude) — without that the footprint would be visibly rectangular and
    /// under-cover the model on its east and west sides.
    private static func squareFootprint(
        around center: CLLocationCoordinate2D,
        halfWidthMeters: Double
    ) -> Polygon {
        let metersPerDegreeLat = 111_320.0
        let dLat = halfWidthMeters / metersPerDegreeLat
        let cosLat = max(cos(center.latitude * .pi / 180), 0.000001)
        let dLon = halfWidthMeters / (metersPerDegreeLat * cosLat)

        let ring = [
            CLLocationCoordinate2D(latitude: center.latitude - dLat, longitude: center.longitude - dLon),
            CLLocationCoordinate2D(latitude: center.latitude - dLat, longitude: center.longitude + dLon),
            CLLocationCoordinate2D(latitude: center.latitude + dLat, longitude: center.longitude + dLon),
            CLLocationCoordinate2D(latitude: center.latitude + dLat, longitude: center.longitude - dLon),
            CLLocationCoordinate2D(latitude: center.latitude - dLat, longitude: center.longitude - dLon)
        ]
        return Polygon([ring])
    }

    /// Tears everything down — used when no landmark has a usable model.
    @MainActor
    static func removeAll(from mapboxMap: MapboxMap) {
        if mapboxMap.layerExists(withId: clipLayerId) {
            try? mapboxMap.removeLayer(withId: clipLayerId)
        }
        for layerId in addedLayerIds where mapboxMap.layerExists(withId: layerId) {
            try? mapboxMap.removeLayer(withId: layerId)
        }
        addedLayerIds.removeAll()
        if mapboxMap.sourceExists(withId: clipSourceId) {
            try? mapboxMap.removeSource(withId: clipSourceId)
        }
        if mapboxMap.sourceExists(withId: sourceId) {
            try? mapboxMap.removeSource(withId: sourceId)
        }
        for modelId in registeredModelIds {
            try? mapboxMap.removeStyleModel(modelId: modelId)
        }
        registeredModelIds.removeAll()
    }
}
