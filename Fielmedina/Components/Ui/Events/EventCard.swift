//
//  EventCard.swift
//  Fielmedina
//
//  Created by Aslan on 1/9/26.
//

import SwiftUI

struct EventCardView: View {
    let event: Event
    let cardWidth: CGFloat = 320
    let cardHeight: CGFloat = 380
    
    var body: some View {
        ZStack(alignment: .bottom) {
            FielmedinaImage(url: event.imageURL, contentMode: .fill)
                .frame(width: cardWidth, height: cardHeight)
                .clipped()
            
            
            LinearGradient(
                colors: [.clear, .black.opacity(0.7), .black.opacity(0.85)],
                startPoint: .center,
                endPoint: .bottom
            )
            
           
            VStack {
                HStack {
                    PriceBadge(price: event.displayPrice, isFree: event.isFree)
                    Spacer()
                }
                Spacer()
            }
            .padding(16)
            
            
            VStack(alignment: .leading, spacing: 8) {
                Text(event.displayName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(event.displayFullInfo)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(.rect(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }
}


private struct PriceBadge: View {
    let price: String
    let isFree: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if isFree {
                Text("Free")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(Color.accentColor)
            } else {
                Text("From")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.accentColor)
                Text(price)
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.systemBackground).opacity(0.95))
        .clipShape(.rect(cornerRadius: 12, style: .continuous))
    }
}
