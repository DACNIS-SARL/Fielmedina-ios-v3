//
//  LocationSkeleton.swift
//  Fielmedina
//
//  Created by Antigravity on 2/25/26.
//

import SwiftUI

struct LocationCardSkeleton: View {
    let cardWidth: CGFloat = 320
    let cardHeight: CGFloat = 380
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Spacer()
            
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 24)
                    .frame(maxWidth: .infinity)
                
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(width: 80, height: 28)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(width: 100, height: 28)
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .padding(.top, 40) // Match the curve padding
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .redacted(reason: .placeholder)
    }
}

struct LocationItemSkeleton: View {
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 20)
                    .frame(maxWidth: .infinity)
                
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(width: 60, height: 14)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(width: 80, height: 14)
                }
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
        LocationCardSkeleton()
        LocationItemSkeleton()
            .padding(.horizontal)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
