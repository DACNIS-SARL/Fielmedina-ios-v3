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
    let cardWidth: CGFloat = 320
    let cardHeight: CGFloat = 300
    
    private var isFree: Bool {
            event.price.lowercased() == "free" ||
            event.price == "0" ||
            event.price.isEmpty
        }

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
                if !isFree{
                    Text("From")
                        .font(.custom("filmedinaSize", size: 16))
                        .foregroundColor(.accentColor)
                        .bold()
                }
                if isFree {
                    Text(event.price)
                        .font(.title3)
                        .foregroundColor(.accentColor)
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                } else {
                    Text(event.price)
                        .font(.subheadline)
                }
                
            }
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 12
                )
            )
            .padding(.top, 12)
            .offset(y: -(cardHeight / 2) + 50)
            
            
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 4)
    }
}

