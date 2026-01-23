//
//  EventDetailView.swift
//  Fielmedina
//
//  Created by Aslan on 1/23/26.
//

import SwiftUI

struct EventDetailView: View {
    let event: Event

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                HeroBanner(
                    imageURL: event.imageURL,
                    showText: false
                )
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
        }
        .coordinateSpace(name: "scroll")
        .ignoresSafeArea(edges: .top)
        .ignoresSafeArea(edges: .horizontal)
        .navigationTitle(event.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SettingsButton()
            }
        }
    }
}

//#Preview {
//    EventDetailView(event: Event.sampleEvents[0])
//}
