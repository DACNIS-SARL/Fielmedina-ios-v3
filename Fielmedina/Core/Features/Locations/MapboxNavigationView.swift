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
        return navigationViewController
    }

    func updateUIViewController(_ uiViewController: NavigationViewController, context: Context) {
        context.coordinator.reportReadyIfNeeded()
    }

    final class Coordinator: NSObject, NavigationViewControllerDelegate {
        private let onReady: () -> Void
        private let onDismiss: () -> Void
        private var didReportReady = false

        init(onReady: @escaping () -> Void, onDismiss: @escaping () -> Void) {
            self.onReady = onReady
            self.onDismiss = onDismiss
        }

        func reportReadyIfNeeded() {
            guard !didReportReady else { return }
            didReportReady = true
            onReady()
        }

        func navigationViewControllerDidDismiss(
            _ navigationViewController: NavigationViewController,
            byCanceling canceled: Bool
        ) {
            onDismiss()
        }
    }
}
