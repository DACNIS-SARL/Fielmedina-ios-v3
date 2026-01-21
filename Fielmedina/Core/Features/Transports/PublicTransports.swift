//
//  PublicTransports.swift
//  Fielmedina
//
//  Created by Aslan on 1/21/26.
//

import SwiftUI

struct PublicTransports: View {
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "train.side.rear.car")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Public Transport")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Routes and schedules coming soon!")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Spacer()
        }
        .navigationTitle("Public Transport")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SettingsButton()
            }
        }
    }
}

#Preview {
    NavigationStack {
        PublicTransports()
    }
}