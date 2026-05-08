//
//  AllTopPicks.swift
//  Fielmedina
//
//  Created by Aslan on 4/5/2026.
//

import SwiftUI

struct AllTopPicks: View {
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
                        
                        Text("Our Pick")
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
        .navigationTitle("Our Pick")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SettingsButton()
            }
        }
        
    }
}
