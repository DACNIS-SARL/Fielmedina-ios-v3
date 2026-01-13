//
//  HomeView.swift
//  Fielmedina
//
//  Created by Aslan on 1/7/26.
//

import SwiftUI

struct HomeView: View {
    let events = EventsData.sampleEvents

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    CarouselList(title: "Best Experiences", subtitle: "Top events", events: events)
                    
                    // Other sections...
                    
                }
                .padding(.bottom, 100)
            }
        }

        
                
    }
    

   
}

#Preview {
    HomeView()
        
}

