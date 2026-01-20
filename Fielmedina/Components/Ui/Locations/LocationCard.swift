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
    let cardHeight: CGFloat = 380
    
    var body: some View {
        VStack(spacing: 0) {
            // Image Section with Category Badge
            ZStack(alignment: .topTrailing) {
                FielmedinaImage(url: location.imageURL, contentMode: .fill)
                    .frame(width: cardWidth, height: cardHeight * 0.55)
                    .clipped()
                
                // Category badge
                if let category = location.category {
                    Text(category.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background {
                            Capsule()
                                .fill(Color.accentColor)
                        }
                        .padding(12)
                }
            }
            .frame(width: cardWidth, height: cardHeight * 0.55)
            
            // Content Section
            VStack(alignment: .leading, spacing: 12) {
                Text(location.displayName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Info chips row - time and admission side by side
                HStack(spacing: 8) {
                    if let schedule = location.displaySchedule {
                        InfoChip(
                            icon: "clock.fill",
                            text: schedule,
                            style: .secondary
                        )
                    }
                    
                    InfoChip(
                        icon: location.isFree ? "checkmark.seal.fill" : "ticket.fill",
                        text: location.isFree ? "Free Entry" : "\(location.displayAdmission) TND",
                        style: location.isFree ? .accent : .primary
                    )
                    
                    Spacer(minLength: 0)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.systemBackground))
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
    }
}

// MARK: - Info Chip Component

private struct InfoChip: View {
    let icon: String
    let text: String
    let style: ChipStyle
    
    enum ChipStyle {
        case primary, secondary, accent
        
        var backgroundColor: Color {
            switch self {
            case .primary: return Color(.systemGray5)
            case .secondary: return Color(.systemGray6)
            case .accent: return Color.accentColor.opacity(0.12)
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .primary
            case .secondary: return .secondary
            case .accent: return Color.accentColor
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(style.foregroundColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(style.backgroundColor, in: Capsule())
    }
}

// MARK: - Preview

#Preview {
    LocationCardView(
        location: Location(
            id: "1",
            nameEn: "Ribat de Sousse",
            nameFr: "Ribat de Sousse",
            latitude: 35.8256,
            longitude: 10.6411,
            category: LocationCategory(
                id: "1",
                nameEn: "Historical Site",
                nameFr: "Site Historique"
            ),
            images: nil,
            openFrom: "09:00",
            openTo: "16:00",
            storyEn: nil,
            storyFr: nil,
            admissionFee: "8.00",
            closedDays: nil
        )
    )
    .padding()
}
