//
//  HikingView.swift
//  Fielmedina
//
//  Created by Aslan on 1/8/26.
//

import SwiftUI

struct HikingView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "figure.hiking")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Hiking Trails")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("Discover beautiful trails coming soon!")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsButton()
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

#Preview {
    HikingView()
}