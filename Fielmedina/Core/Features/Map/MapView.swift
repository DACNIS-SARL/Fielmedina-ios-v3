//
//  MapView.swift
//  Fielmedina
//
//  Created by Aslan on 1/8/26.
//

import SwiftUI
import MapboxMaps

struct MapView: View {
    @State private var locationManager = LocationManager()
    @State private var viewport: Viewport = .camera(
        center: CLLocationCoordinate2D(
            latitude: 35.825892,
            longitude: 10.637448
        ),
        zoom: 15,
        bearing: 0,
        pitch: 40
    )
    @State private var showLocationAlert = false
    
    var body: some View {
        ZStack {
            Map(viewport: $viewport) {
                Puck2D(bearing: .heading)
            }
            .ignoresSafeArea()
            
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    if locationManager.authorizationStatus == .authorizedWhenInUse ||
                       locationManager.authorizationStatus == .authorizedAlways {
                        Button(action: {
                            withViewportAnimation(.default(maxDuration: 1)) {
                                viewport = .followPuck(zoom: 18, bearing: .heading, pitch: 40)
                            }
                            FirebaseUtils.trackButtonTap(buttonName: "center_on_user_location", screenName: "Home")
                        }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color(red: 0.702, green: 0.435, blue: 0.227))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                    } else if locationManager.authorizationStatus == .denied ||
                              locationManager.authorizationStatus == .restricted {
                        Button(action: {
                            showLocationAlert = true
                            FirebaseUtils.trackButtonTap(buttonName: "request_location_settings", screenName: "Home")
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "location.slash.fill")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Enable location")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(red: 0.702, green: 0.435, blue: 0.227))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                    } else {
                        Button(action: {
                            locationManager.requestPermission()
                            FirebaseUtils.trackButtonTap(buttonName: "request_location_permission", screenName: "Home")
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Enable location")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(red: 0.702, green: 0.435, blue: 0.227))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            locationManager.requestPermission()
        }
        .alert("Location Access Required", isPresented: $showLocationAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                FirebaseUtils.trackButtonTap(buttonName: "open_location_settings", screenName: "Home")
            }
        } message: {
            Text("To use this feature, please enable location access in Settings. Tap 'Location' and select 'While Using the App'.")
        }
    }
}

#Preview {
    MapView()
}
