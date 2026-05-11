//
//  LocationCard.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import SwiftUI

struct CardCurveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addCurve(
            to: CGPoint(x: rect.width, y: 50),
            control1: CGPoint(x: rect.width * 0.4, y: 0),
            control2: CGPoint(x: rect.width * 0.6, y: 60)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}

struct LocationCardView: View {
    let location: Location
    let cardWidth: CGFloat = 320
    let cardHeight: CGFloat = 380
    
    var body: some View {
        ZStack(alignment: .bottom) {
            FielmedinaImage(url: location.imageURL, contentMode: .fill)
                .frame(width: cardWidth, height: cardHeight)
                .clipped()
            
            VStack(alignment: .leading, spacing: 12) {
                Text(location.displayName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 35)
                
                if location.hasScheduleInfo || location.hasAdmissionInfo {
                    HStack(spacing: 8) {
                        if let schedule = location.displaySchedule {
                            InfoChip(
                                icon: "clock.fill",
                                text: schedule,
                                style: .secondary
                            )
                        }
                        
                        if location.hasAdmissionInfo {
                            if location.isFree {
                                InfoChip(
                                    icon: "checkmark.seal.fill",
                                    text: "Free Entry",
                                    style: .accent
                                )
                            } else if let admission = location.displayAdmission {
                                InfoChip(
                                    icon: "ticket.fill",
                                    text: "\(admission) TND",
                                    style: .primary
                                )
                            }
                        }
                        
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(20)
            .background {
                CardCurveShape()
                    .fill(Color(.systemBackground))
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(.rect(cornerRadius: 30, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
        .overlay(alignment: .topTrailing) {
            if let category = location.category {
                Text(category.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.accentColor))
                    .padding(16)
            }
        }
    }
}

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
            closedDays: nil,
            voiceoverEn: nil,
            voiceoverFr: nil
        )
    )
    .padding()
}
