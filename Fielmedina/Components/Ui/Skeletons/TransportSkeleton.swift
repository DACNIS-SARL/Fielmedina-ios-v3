//
//  TransportSkeleton.swift
//  Fielmedina
//
//  Created by Antigravity on 2/25/26.
//

import SwiftUI

struct TransportRouteSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 120, height: 28)
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(0..<2, id: \.self) { _ in
                    HStack(alignment: .top, spacing: 12) {
                        routeSectionSkeleton
                        routeSectionSkeleton
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .redacted(reason: .placeholder)
    }
    
    private var routeSectionSkeleton: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray5))
                        .frame(width: 80, height: 16)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 16)
                }
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(width: 60, height: 24)
            }
            
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(height: 16)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 32) {
            TransportRouteSkeleton()
            TransportRouteSkeleton()
        }
        .padding(26)
    }
}
