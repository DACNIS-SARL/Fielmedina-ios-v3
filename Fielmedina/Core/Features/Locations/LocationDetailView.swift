//
//  LocationDetailView.swift
//  Fielmedina
//
//  Created by Aslan on 1/23/26.
//

import SwiftUI


struct LocationDetailView: View {
    var body: some View {
        ScrollView(showsIndicators: false){
            LazyVStack(alignment: .leading, spacing: 0){
                HeroBanner(imageName: "booking-taxi", showText: false)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
        }
        .coordinateSpace(name: "scroll")
                .ignoresSafeArea(edges: .top)
                .ignoresSafeArea(edges: .horizontal)
                .navigationTitle("Book a Taxi")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        SettingsButton()
                    }
                }
    }
    
}

#Preview {
    LocationDetailView()
}
