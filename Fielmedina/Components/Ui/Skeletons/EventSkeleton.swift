//
//  EventSkeleton.swift
//  Fielmedina
//
//  Created by Antigravity on 2/25/26.
//

import SwiftUI

struct EventCardSkeleton: View {
    let cardWidth: CGFloat = 320
    let cardHeight: CGFloat = 380
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGray5)
                .frame(width: cardWidth, height: cardHeight)
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 24)
                    .frame(maxWidth: .infinity)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 140, height: 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .redacted(reason: .placeholder)
    }
}

struct EventItemSkeleton: View {
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 20)
                    .frame(maxWidth: .infinity)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(width: 100, height: 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 20)
            .padding(.vertical, 16)
            
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(.systemGray5))
                .frame(width: 100, height: 100)
                .clipShape(
                    .rect(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 16,
                        topTrailingRadius: 16
                    )
                )
        }
        .frame(height: 100)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .redacted(reason: .placeholder)
    }
}

#Preview {
    VStack(spacing: 20) {
        EventCardSkeleton()
        EventItemSkeleton()
            .padding(.horizontal)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
