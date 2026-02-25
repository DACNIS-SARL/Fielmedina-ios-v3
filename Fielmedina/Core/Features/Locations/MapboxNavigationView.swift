//
//  MapboxNavigationView.swift
//  Fielmedina
//
//  Created by Aslan on 1/24/26.
//

import SwiftUI
import UIKit
import MapboxNavigationCore
import MapboxNavigationUIKit
import MapboxMaps
import CoreLocation


struct MapboxNavigationView: UIViewControllerRepresentable {
    let navigationRoutes: NavigationRoutes
    let mapboxNavigationProvider: MapboxNavigationProvider
    let userLocation: CLLocationCoordinate2D?
    let onReady: () -> Void
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onReady: onReady,
            onDismiss: onDismiss,
            mapboxNavigationProvider: mapboxNavigationProvider
        )
    }

    func makeUIViewController(context: Context) -> NavigationViewController {
        let mapboxNavigation = mapboxNavigationProvider.mapboxNavigation
        let navigationOptions = NavigationOptions(
            mapboxNavigation: mapboxNavigation,
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
        navigationViewController.usesNightStyleInDarkMode = true
        navigationViewController.showsSpeedLimits = false
        navigationViewController.routeLineTracksTraversal = true
        
        if let userLocation = userLocation {
            DispatchQueue.main.async {
                navigationViewController.navigationMapView?.mapView.mapboxMap.setCamera(to: CameraOptions(
                    center: userLocation,
                    zoom: 16.0,
                    bearing: 0,
                    pitch: 40
                ))
            }
        }
        
        context.coordinator.scheduleReadyCallback()
        
        return navigationViewController
    }

    func updateUIViewController(_ uiViewController: NavigationViewController, context: Context) {
        // No-op: ready state is handled via scheduled callback
    }

    final class Coordinator: NSObject, NavigationViewControllerDelegate {
        private let onReady: () -> Void
        private let onDismiss: () -> Void
        let mapboxNavigationProvider: MapboxNavigationProvider
        private var didReportReady = false
        private var readyWorkItem: DispatchWorkItem?

        init(onReady: @escaping () -> Void, onDismiss: @escaping () -> Void, mapboxNavigationProvider: MapboxNavigationProvider) {
            self.onReady = onReady
            self.onDismiss = onDismiss
            self.mapboxNavigationProvider = mapboxNavigationProvider
        }
        
        func scheduleReadyCallback() {
            guard readyWorkItem == nil else { return }
            
            let workItem = DispatchWorkItem { [weak self] in
                self?.reportReadyIfNeeded()
            }
            readyWorkItem = workItem
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: workItem)
        }

        func reportReadyIfNeeded() {
            guard !didReportReady else { return }
            didReportReady = true
            onReady()
        }
        
        func cancelReadyCallback() {
            readyWorkItem?.cancel()
            readyWorkItem = nil
        }

        func navigationViewControllerDidDismiss(
            _ navigationViewController: NavigationViewController,
            byCanceling canceled: Bool
        ) {
            cancelReadyCallback()
            onDismiss()
        }
    }
}

