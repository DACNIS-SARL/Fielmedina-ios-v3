//
//  TaxiBooking.swift
//  Fielmedina
//
//  Created by Aslan on 1/21/26.
//

import SwiftUI

struct TaxiBooking: View {
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "car.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
                Text("Taxi Booking")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Coming soon!")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .navigationTitle("Book a Taxi")
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
        TaxiBooking()
    }
}