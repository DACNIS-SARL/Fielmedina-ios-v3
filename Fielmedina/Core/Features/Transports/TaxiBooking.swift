//
//  TaxiBooking.swift
//  Fielmedina
//
//  Created by Aslan on 1/21/26.
//

import SwiftUI

struct TaxiBooking: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        ScrollView(showsIndicators: false){
            LazyVStack(alignment: .leading, spacing: 0) {
                HeroBanner(imageName: "booking-taxi", showText: false)
                    .frame(maxWidth: .infinity)
                
                VStack {
                    VStack(spacing: 16){
                        Image(systemName: "car.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text("Taxi Booking")
                            .font(.system(size: 24, weight: .bold))
                        
                        Text("Coming soon!")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .containerRelativeFrame(.vertical){
                    size, axis in
                    size - (verticalSizeClass == .compact ? 180.0 : 320.0)
                }
                
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
    NavigationStack {
        TaxiBooking()
    }
}
