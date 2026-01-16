//
//  EventItem.swift
//  Fielmedina
//
//  Created by Aslan on 1/13/26.
//

import SwiftUI

struct EventItem: View {
    let event: Event
    @Environment(\.colorScheme) var colorScheme
        
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(event.displayName) // Use displayName
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(event.displayDate) // Use displayDate
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 20)
            .padding(.vertical, 16)
            
            // Use FielmedinaImage with imageURL
            FielmedinaImage(url: event.imageURL, contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipped()
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
        .background(
            colorScheme == .dark
                ? Color(.systemGray6)
                : Color(.systemBackground)
        )
        .clipShape(.rect(cornerRadius: 16))
        .shadow(
            color: colorScheme == .dark
                ? Color.white.opacity(0.05)
                : Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 2
        )
    }
}
