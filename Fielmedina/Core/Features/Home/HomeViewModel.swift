//
//  HomeViewModel.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import SwiftUI
import Observation

@Observable @MainActor
class HomeViewModel {
    // Data properties
    var events: [Event] = []
    var locations: [Location] = []
    
    // UI State properties
    var isLoading = true
    var errorMessage: String?
    var showTaxiButton = false
    
    /// Loads all data required for the Home screen.
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Using a TaskGroup for parallel fetching
            try await withThrowingTaskGroup(of: Void.self) { group in
                // Add Event fetching
                group.addTask {
                    let fetchedEvents = try await EventService.shared.fetchEvents()
                    await MainActor.run {
                        self.events = fetchedEvents
                    }
                }
                
                // Add Location fetching
                group.addTask {
                    let fetchedLocations = try await LocationService.shared.fetchLocations(limit: 10)
                    await MainActor.run {
                        self.locations = fetchedLocations
                    }
                }
                
                try await group.waitForAll()
            }
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
