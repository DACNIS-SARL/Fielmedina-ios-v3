//
//  HeroBanner.swift
//  Fielmedina
//
//  Created by Aslan on 1/15/26.
//


import SwiftUI

struct HeroBanner: View {
    let showTaxiButton: Bool
    
    init(showTaxiButton: Bool = true) {
        self.showTaxiButton = showTaxiButton
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("hero-bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.25),
                        Color.clear,
                        Color.black.opacity(0.15)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Text("Tunisia")
                            .font(.system(size: 70, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4)
                        
                        Text("welcome")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        NavigationLink(value: HomeNavigationDestination.publicTransports) {
                            HStack(spacing: 10) {
                                Image(systemName: "train.side.rear.car")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Public transports")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: 250)
                            .frame(height: 56)
                            .background(Color.blue)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.15), radius: 6)
                            .contentShape(Capsule())
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            FirebaseUtils.trackButtonTap(
                                buttonName: "public_transport",
                                screenName: "Home"
                            )
                        })
                        
                        if showTaxiButton {
                            NavigationLink(value: HomeNavigationDestination.taxiBooking) {
                                HStack(spacing: 10) {
                                    Image(systemName: "car.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Book a Taxi")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundStyle(.black)
                                .frame(maxWidth: 250)
                                .frame(height: 56)
                                .background(Color.yellow)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.15), radius: 6)
                                .contentShape(Capsule())
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                FirebaseUtils.trackButtonTap(
                                    buttonName: "book_taxi",
                                    screenName: "Home"
                                )
                            })
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, -30)
                }
            }
        }
        .frame(height: 350)
    }
}
