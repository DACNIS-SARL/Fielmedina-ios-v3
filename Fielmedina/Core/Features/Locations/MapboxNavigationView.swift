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

/// SwiftUI wrapper for Mapbox NavigationViewController.
/// Handles the lifecycle of turn-by-turn navigation UI.
struct MapboxNavigationView: UIViewControllerRepresentable {
    let navigationRoutes: NavigationRoutes
    let mapboxNavigationProvider: MapboxNavigationProvider
    let onReady: () -> Void
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onReady: onReady, onDismiss: onDismiss)
    }

    func makeUIViewController(context: Context) -> NavigationViewController {
        let mapboxNavigation = mapboxNavigationProvider.mapboxNavigation
        let navigationOptions = NavigationOptions(
            mapboxNavigation: mapboxNavigation,
            voiceController: mapboxNavigationProvider.routeVoiceController,
            eventsManager: mapboxNavigationProvider.eventsManager()
        )
        let navigationViewController = NavigationViewController(
            navigationRoutes: navigationRoutes,
            navigationOptions: navigationOptions
        )
        navigationViewController.delegate = context.coordinator
        navigationViewController.modalPresentationStyle = .fullScreen
        navigationViewController.usesNightStyleInDarkMode = true
        
        // Schedule ready callback after a short delay to allow map to render
        context.coordinator.scheduleReadyCallback()
        
        return navigationViewController
    }

    func updateUIViewController(_ uiViewController: NavigationViewController, context: Context) {
        // No-op: ready state is handled via scheduled callback
    }

    final class Coordinator: NSObject, NavigationViewControllerDelegate {
        private let onReady: () -> Void
        private let onDismiss: () -> Void
        private var didReportReady = false
        private var readyWorkItem: DispatchWorkItem?

        init(onReady: @escaping () -> Void, onDismiss: @escaping () -> Void) {
            self.onReady = onReady
            self.onDismiss = onDismiss
        }
        
        /// Schedules the ready callback after a delay to ensure map tiles load.
        /// The delay gives NavigationViewController time to fully initialize its map view.
        func scheduleReadyCallback() {
            guard readyWorkItem == nil else { return }
            
            let workItem = DispatchWorkItem { [weak self] in
                self?.reportReadyIfNeeded()
            }
            readyWorkItem = workItem
            
            // 0.8 second delay: enough for map tiles to load on most network conditions
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

