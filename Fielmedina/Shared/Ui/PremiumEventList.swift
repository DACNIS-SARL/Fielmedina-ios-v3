//
//  Untitled.swift
//  Fielmedina
//
//  Created by Aslan on 1/9/26.
//

import SwiftUI

struct HorizontalEventListView: View {
    let events: [Event] = [
        Event(
            title: "7th International Festival of Circus and Street Arts",
            date: "Thu, Feb 13, 8:30PM", price: "145 TND", imageName: "event-e"),
        Event(
            title: "Local Music Concert",
            date: "Fri, Mar 20, 7:00PM", price: "50 TND", imageName: "event-e"),
        Event(
            title: "Art Exhibition Opening",
            date: "Sat, Apr 1, 4:00PM", price: "Free", imageName: "event-e")
    ]
    
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
