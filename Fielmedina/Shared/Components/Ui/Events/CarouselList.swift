//
//  Untitled.swift
//  Fielmedina
//
//  Created by Aslan on 1/9/26.
//

import SwiftUI

struct HorizontalEventListView: View {
    let events = EventsData.sampleEvents
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Upcoming Events")
                .font(.largeTitle)
                .bold()
                .padding(.horizontal)
                

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(events) { event in
                        EventCardView(event: event)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}


#Preview {
    HorizontalEventListView()
}
