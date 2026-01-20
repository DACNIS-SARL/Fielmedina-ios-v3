//
//  LocationCard.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//


import SwiftUI

struct LocationCardView: View {
    let location: Location
    let cardWidth: CGFloat = 320
    let cardHeight: CGFloat = 400
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomTrailing) {
                FielmedinaImage(url: location.imageURL, contentMode: .fill)
                    .frame(width: cardWidth, height: cardHeight * 0.65)
                    .clipped()
                
                if let category = location.category {
                    Text(category.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background {
                            ZStack {
                                Capsule().fill(.ultraThinMaterial)
                                Capsule().fill(Color.accentColor.opacity(0.70))
                            }
                        }
                        .overlay {
                            Capsule()
                                .strokeBorder(.primary.opacity(0.1), lineWidth: 0.5)
                        }
                        .padding(16)
                }
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text(location.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let schedule = location.displaySchedule {
                    HStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                        Text(schedule)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                    Text(location.displayAdmission + "TND")  // Added TND
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}
