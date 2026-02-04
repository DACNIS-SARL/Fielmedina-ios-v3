//
//  MapboxHikingNavigationView.swift
//  Fielmedina
//
//  Created by Aslan on 1/25/26.
//

import SwiftUI
import MapboxNavigationCore
import MapboxNavigationUIKit
import MapboxDirections
import MapboxMaps
import CoreLocation

struct MapboxHikingNavigationView: UIViewControllerRepresentable {
    let navigationRoutes: NavigationRoutes
    let hikingRoute: Hiking
    let completedWaypoints: Set<Int>
    let onDismiss: () -> Void
    let onWaypointCompleted: (Int) -> Void
    let onWaypointTapped: (TrailWaypoint) -> Void
    let onProgressUpdate: (Int) -> Void
    
    func makeUIViewController(context: Context) -> NavigationViewController {
        let mapboxNavigationProvider = MapboxNavigationProviderStore.shared
        
       
        let navigationOptions = NavigationOptions(
            mapboxNavigation: mapboxNavigationProvider.mapboxNavigation,
            voiceController: mapboxNavigationProvider.routeVoiceController,
            eventsManager: mapboxNavigationProvider.eventsManager(),
            predictiveCacheManager: mapboxNavigationProvider.predictiveCacheManager
        )
        
        let navigationViewController = NavigationViewController(
            navigationRoutes: navigationRoutes,
            navigationOptions: navigationOptions
        )
        
        navigationViewController.delegate = context.coordinator
        navigationViewController.modalPresentationStyle = .fullScreen
        navigationViewController.showsSpeedLimits = false
        navigationViewController.routeLineTracksTraversal = true
        
        // Set initial camera position to user location
        if let userLocation = LocationManager.shared.userLocation {
            let cameraOptions = CameraOptions(
                center: userLocation,
                zoom: 15.0,
                bearing: 0.0,
                pitch: 0.0
            )
            DispatchQueue.main.async {
                navigationViewController.navigationMapView?.mapView.mapboxMap.setCamera(to: cameraOptions)
            }
        }
        
        // Add custom waypoint markers with rounded images and enable tap handling
        if let mapView = navigationViewController.navigationMapView?.mapView {
            buildCustomWaypointAnnotations(on: mapView, coordinator: context.coordinator)
        } else {
            print("❌ MapView not available for adding markers")
        }
        
        return navigationViewController
    }
    
    func updateUIViewController(_ uiViewController: NavigationViewController, context: Context) {
        // We can update annotations if completedWaypoints changes, but usually the coordinator handles local state
        // Re-drawing annotations on every update might be heavy, so we rely on the makeCoordinator logic mostly.
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Annotation Building Logic
    
    private func buildCustomWaypointAnnotations(on mapView: MapboxMaps.MapView, coordinator: Coordinator) {
        let manager = mapView.annotations.makePointAnnotationManager()
        var annotations: [PointAnnotation] = []
        
        let waypoints = hikingRoute.waypoints
        
        for (index, waypoint) in waypoints.enumerated() {
            let coordinate = CLLocationCoordinate2D(latitude: waypoint.latitude, longitude: waypoint.longitude)
            let annotationId = "waypoint-\(index)"
            let isCompleted = completedWaypoints.contains(index)
            
            // Determine image
            var annotationImage: UIImage
            if let imageURL = waypoint.images?.first?.displayURL,
               let cachedImage = coordinator.cachedImage(for: imageURL) {
                annotationImage = createRoundedWaypointImage(
                    image: cachedImage,
                    waypointNumber: index + 1,
                    completed: isCompleted
                )
            } else if waypoint.images?.first != nil {
                annotationImage = createDefaultWaypointImage(waypointNumber: index + 1, completed: isCompleted)
            } else if index == waypoints.count - 1 {
                annotationImage = createFinishFlagImage()
            } else {
                annotationImage = createDefaultWaypointImage(waypointNumber: index + 1, completed: isCompleted)
            }
            
            var pointAnnotation = PointAnnotation(id: annotationId, coordinate: coordinate)
            pointAnnotation.image = .init(image: annotationImage, name: "waypoint_\(index)_\(isCompleted)")
            pointAnnotation.iconAnchor = .bottom
            
            // Tap Handler
            let waypointToSend = waypoint
            pointAnnotation.tapHandler = { _ in
                DispatchQueue.main.async {
                    FirebaseUtils.trackButtonTap(buttonName: "hiking_waypoint_\(index)", screenName: "HikingNavigation")
                    coordinator.parent.onWaypointTapped(waypointToSend)
                }
                return true
            }
            
            annotations.append(pointAnnotation)
        }
        
        manager.annotations = annotations
        coordinator.annotationManager = manager
        coordinator.loadWaypointImages(waypoints: waypoints, completedWaypoints: completedWaypoints)
    }
    
    // MARK: - Image Generators
    
    private func createDefaultWaypointImage(waypointNumber: Int, completed: Bool) -> UIImage {
        let size = CGSize(width: 40, height: 40)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(ovalIn: rect)
            
            let color = completed ? UIColor.systemGreen : UIColor.systemBlue
            color.setFill()
            path.fill()
            
            UIColor.white.setStroke()
            path.lineWidth = 2
            path.stroke()
            
            let text = "\(waypointNumber)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }

    private func createRoundedWaypointImage(image: UIImage, waypointNumber: Int, completed: Bool) -> UIImage {
        let size = CGSize(width: 44, height: 44)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(ovalIn: rect)
            path.addClip()

            let scale = max(size.width / image.size.width, size.height / image.size.height)
            let scaledSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let origin = CGPoint(
                x: (size.width - scaledSize.width) / 2,
                y: (size.height - scaledSize.height) / 2
            )
            image.draw(in: CGRect(origin: origin, size: scaledSize))

            UIColor.white.setStroke()
            path.lineWidth = 2
            path.stroke()

            let badgeSize: CGFloat = 18
            let badgeRect = CGRect(
                x: size.width - badgeSize,
                y: size.height - badgeSize,
                width: badgeSize,
                height: badgeSize
            )
            let badgePath = UIBezierPath(ovalIn: badgeRect)
            let badgeColor = completed ? UIColor.systemGreen : UIColor.systemBlue
            badgeColor.setFill()
            badgePath.fill()

            let text = "\(waypointNumber)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 10),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: badgeRect.midX - textSize.width / 2,
                y: badgeRect.midY - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    private func createFinishFlagImage() -> UIImage {
        let size = CGSize(width: 40, height: 40)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
             let text = "🏁"
             let attributes: [NSAttributedString.Key: Any] = [
                 .font: UIFont.systemFont(ofSize: 30)
             ]
             let textSize = text.size(withAttributes: attributes)
             let textRect = CGRect(
                 x: (size.width - textSize.width) / 2,
                 y: (size.height - textSize.height) / 2,
                 width: textSize.width,
                 height: textSize.height
             )
             text.draw(in: textRect, withAttributes: attributes)
        }
    }

    class Coordinator: NSObject, NavigationViewControllerDelegate {
        private static let imageCache = NSCache<NSString, UIImage>()
        let parent: MapboxHikingNavigationView
        var annotationManager: PointAnnotationManager?
        private var waypointImages: [String: UIImage] = [:]
        
        init(_ parent: MapboxHikingNavigationView) {
            self.parent = parent
        }
        
        func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
            parent.onDismiss()
        }
        
        func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
            // Mapbox triggers this when arriving at a waypoint defined in the Route
            // We need to match it to our hiking waypoints
            if let name = waypoint.name {
                 // Simple logic: lookup index by name or location match
                 if let index = parent.hikingRoute.waypoints.firstIndex(where: { $0.name == name }) {
                     parent.onWaypointCompleted(index)
                     // Update marker appearance
                     updateMarkerToCompleted(index: index)
                 }
            }
            
            return true // Continue navigation
        }

        func navigationViewController(_ navigationViewController: NavigationViewController, didUpdate progress: RouteProgress) {
            parent.onProgressUpdate(progress.legIndex)
        }
        
        private func updateMarkerToCompleted(index: Int) {
            guard let annotationManager else { return }
            let annotationId = "waypoint-\(index)"
            let waypointNumber = index + 1

            let image: UIImage
            if let baseImage = waypointImages[annotationId] {
                image = parent.createRoundedWaypointImage(image: baseImage, waypointNumber: waypointNumber, completed: true)
            } else {
                image = parent.createDefaultWaypointImage(waypointNumber: waypointNumber, completed: true)
            }

            updateAnnotationImage(
                manager: annotationManager,
                annotationId: annotationId,
                image: image,
                imageName: "waypoint_\(index)_completed"
            )
        }

        func loadWaypointImages(waypoints: [TrailWaypoint], completedWaypoints: Set<Int>) {
            for (index, waypoint) in waypoints.enumerated() {
                guard let urlString = waypoint.images?.first?.displayURL,
                      let url = URL(string: urlString) else {
                    continue
                }

                let annotationId = "waypoint-\(index)"
                let waypointNumber = index + 1
                let isCompleted = completedWaypoints.contains(index)

                if let cachedImage = Self.imageCache.object(forKey: urlString as NSString) {
                    waypointImages[annotationId] = cachedImage
                    if let annotationManager {
                        let image = parent.createRoundedWaypointImage(
                            image: cachedImage,
                            waypointNumber: waypointNumber,
                            completed: isCompleted
                        )
                        updateAnnotationImage(
                            manager: annotationManager,
                            annotationId: annotationId,
                            image: image,
                            imageName: "waypoint_\(index)_cached"
                        )
                    }
                    continue
                }

                if let cachedResponse = URLCache.shared.cachedResponse(for: URLRequest(url: url)),
                   let cachedImage = UIImage(data: cachedResponse.data) {
                    Self.imageCache.setObject(cachedImage, forKey: urlString as NSString)
                    waypointImages[annotationId] = cachedImage
                    if let annotationManager {
                        let image = parent.createRoundedWaypointImage(
                            image: cachedImage,
                            waypointNumber: waypointNumber,
                            completed: isCompleted
                        )
                        updateAnnotationImage(
                            manager: annotationManager,
                            annotationId: annotationId,
                            image: image,
                            imageName: "waypoint_\(index)_cached_response"
                        )
                    }
                    continue
                }

                Task { @MainActor [weak self] in
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        guard let downloaded = UIImage(data: data) else { return }
                        Self.imageCache.setObject(downloaded, forKey: urlString as NSString)

                        guard let self else { return }
                        self.waypointImages[annotationId] = downloaded
                        guard let annotationManager = self.annotationManager else { return }
                        let image = self.parent.createRoundedWaypointImage(
                            image: downloaded,
                            waypointNumber: waypointNumber,
                            completed: isCompleted
                        )
                        self.updateAnnotationImage(
                            manager: annotationManager,
                            annotationId: annotationId,
                            image: image,
                            imageName: "waypoint_\(index)_downloaded"
                        )
                    } catch {
                        return
                    }
                }
            }
        }

        private func updateAnnotationImage(
            manager: PointAnnotationManager,
            annotationId: String,
            image: UIImage,
            imageName: String
        ) {
            var annotations = manager.annotations
            guard let index = annotations.firstIndex(where: { $0.id == annotationId }) else { return }
            var annotation = annotations[index]
            annotation.image = .init(image: image, name: imageName)
            annotations[index] = annotation
            manager.annotations = annotations
        }

        func cachedImage(for urlString: String) -> UIImage? {
            if let cachedImage = Self.imageCache.object(forKey: urlString as NSString) {
                return cachedImage
            }
            guard let url = URL(string: urlString) else { return nil }
            guard let cachedResponse = URLCache.shared.cachedResponse(for: URLRequest(url: url)),
                  let cachedImage = UIImage(data: cachedResponse.data) else { return nil }
            Self.imageCache.setObject(cachedImage, forKey: urlString as NSString)
            return cachedImage
        }
    }
}
