//
//  LocationItem.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import SwiftUI

struct LocationItem: View {
    let location: Location
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(location.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if location.hasScheduleInfo || location.hasAdmissionInfo {
                    HStack(spacing: 12) {
                        if let schedule = location.displaySchedule {
                            Label(schedule, systemImage: "clock")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        
                        if location.hasAdmissionInfo {
                            if location.isFree {
                                Label("Free", systemImage: "checkmark.seal")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.accent)
                            } else if let admission = location.displayAdmission {
                                Label("\(admission) TND", systemImage: "ticket")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 20)
            .padding(.vertical, 16)
            
            FielmedinaImage(url: location.imageURL, contentMode: .fill)
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
