//
//  EventCard.swift
//  Fielmedina
//
//  Created by Aslan on 1/9/26.
//

import SwiftUI

struct Event: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let price: String
    let imageName: String
}


struct EventCardView: View {
    let event: Event
    let cardWidth: CGFloat = 220
    let cardHeight: CGFloat = 300

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(event.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: cardWidth, height: cardHeight)
                .clipped()

           
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            
            VStack(alignment: .leading) {
                Text(event.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(3)
                
                Text(event.date)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()

            
            VStack(alignment: .leading, spacing: 5) {
                Text("From")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(event.price)
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .padding([.top, .leading], 12)
            .offset(y: -(cardHeight / 2) + 120)
        }
        .frame(width: cardWidth, height: cardHeight)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}
