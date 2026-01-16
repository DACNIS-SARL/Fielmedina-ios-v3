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
    
    // UI State properties
    var isLoading = true
    var errorMessage: String?
    var showTaxiButton = false
    
    /// Loads all data required for the Home screen.
    /// This is designed to be easily extensible for Locations, Tips, etc.
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
                
                // FUTURE: Add Location fetching here
                // group.addTask { ... }
                
                // FUTURE: Add Tips fetching here
                // group.addTask { ... }
                
                try await group.waitForAll()
            }
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
