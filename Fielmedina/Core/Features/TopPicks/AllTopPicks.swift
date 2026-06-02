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
                HeroBanner(imageName: "our-pick", showText: false)
                    .frame(maxWidth: .infinity)
                VStack(spacing: 24) {
                    CarouselListMerchants()
                }
                .padding(.vertical, 20)
                
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
