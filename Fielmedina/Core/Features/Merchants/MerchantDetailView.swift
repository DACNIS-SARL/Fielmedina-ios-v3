//
//  MerchantDetailView.swift
//  Fielmedina
//
//  Created by Aslan on 6/8/26.
//

import SwiftUI
import CoreLocation
import MapboxNavigationCore
import MapboxDirections

struct MerchantDetailView: View {
    @State private var merchant: Merchant
    
    init(merchant: Merchant) {
        self._merchant = State(initialValue: merchant)
    }
    
    @State private var selectedImageIndex: Int? = 0
    @State private var locationManager = LocationManager()
    private let mapboxNavigationProvider = MapboxNavigationProviderStore.shared
    @State private var navigationRoutes: NavigationRoutes?
    @State private var isNavigationPresented = false
    @State private var isNavigationLoading = false
    @State private var showLocationAlert = false
    @State private var showNavigationErrorAlert = false
    @State private var navigationErrorMessage = ""
    
    private var currentUserCoordinate: CLLocationCoordinate2D? {
        locationManager.userLocation
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                HeroBanner(imageURL: merchant.imageURL, showText: false)
                    .frame(maxWidth: .infinity)
                
                detailsCard
            }
            .frame(maxWidth: .infinity)
        }
        .coordinateSpace(name: "scroll")
        .ignoresSafeArea(edges: .top)
        .ignoresSafeArea(edges: .horizontal)
        .navigationTitle(merchant.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SettingsButton()
            }
        }
        .task {
            locationManager.requestPermission()
            locationManager.startUpdatingLocation()
            do {
                let fullMerchant = try await MerchantService.shared.fetchMerchant(id: merchant.id)
                await MainActor.run {
                    self.merchant = fullMerchant
                }
            } catch {
                print("Failed to fetch merchant details: \(error)")
            }
        }
        .onDisappear {
            locationManager.stopUpdatingLocation()
        }
        .fullScreenCover(isPresented: $isNavigationPresented) {
            NavigationCoverView(
                routes: $navigationRoutes,
                provider: mapboxNavigationProvider,
                locationName: merchant.displayName,
                userLocation: currentUserCoordinate,
                isLoading: $isNavigationLoading,
                onDismiss: {
                    navigationRoutes = nil
                    isNavigationPresented = false
                    isNavigationLoading = false
                }
            )
        }
        .alert("Location Access Required", isPresented: $showLocationAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("To start navigation, please enable location access in Settings. Tap 'Location' and select 'While Using the App'.")
        }
        .alert("Navigation Error", isPresented: $showNavigationErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(navigationErrorMessage)
        }
        .onAppear {
            FirebaseUtils.trackScreenView(screenName: "merchant_detail_\(merchant.displayName)", screenClass: "MerchantDetailView")
        }
    }
    
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(merchant.displayName)
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            HStack(spacing: 12) {
                Button {
                    FirebaseUtils.trackButtonTap(buttonName: "start_navigation_\(merchant.displayName)", screenName: "MerchantDetailView")
                    startNavigation()
                } label: {
                    Label("Start Navigation", systemImage: "location.north.line")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.72, green: 0.41, blue: 0.25))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            if (merchant.images?.count ?? 0) > 1 {
                imageCarousel
            }
            
            AdsCarousel()
            
            if let category = merchant.category?.displayName {
                Text(category.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.72, green: 0.41, blue: 0.25))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            
            HStack(spacing: 16) {
                if let openFrom = merchant.openFrom, let openTo = merchant.openTo {
                    detailBadge(title: String(localized: "Opening Hours"), value: "\(formatTime(openFrom)) - \(formatTime(openTo))", systemImage: "clock")
                }
                if let priceRange = merchant.priceRange, !priceRange.isEmpty {
                    detailBadge(title: String(localized: "Price Range"), value: priceRange, systemImage: "dollarsign.circle")
                }
                Spacer(minLength: 0)
            }
            
            if let address = merchant.displayAddress {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(Color(red: 0.72, green: 0.41, blue: 0.25))
                    Text(address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                if let phone = merchant.phone, let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                    Button {
                        UIApplication.shared.open(url)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "phone.fill")
                            Text("Call")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .foregroundStyle(Color(red: 0.72, green: 0.41, blue: 0.25))
                        .clipShape(Capsule())
                    }
                }
                
                if let shortLink = merchant.shortLink, let url = URL(string: shortLink) {
                    Button {
                        UIApplication.shared.open(url)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "globe")
                            Text("Website")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .foregroundStyle(Color(red: 0.72, green: 0.41, blue: 0.25))
                        .clipShape(Capsule())
                    }
                }
            }
            
            if let products = merchant.products, !products.isEmpty {
                Divider()
                    .padding(.vertical, 8)
                
                Text(String(localized: "Products & Services"))
                    .font(.title3.weight(.bold))
                
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                    ForEach(products) { product in
                        VStack(alignment: .leading, spacing: 8) {
                            FielmedinaImage(url: product.image, contentMode: .fill)
                                .frame(height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            
                            Text(product.displayName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(2)
                            
                            if let price = product.price {
                                Text("\(price, specifier: "%.2f") TND")
                                    .font(.footnote)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color(red: 0.72, green: 0.41, blue: 0.25))
                            }
                        }
                    }
                }
            }
            
            if let story = merchant.displayDescription {
                HTMLTextView(
                    html: story,
                    textStyle: .body,
                    textColor: .secondary
                )
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 0)
        .padding(.top, -24)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
    
    private var imageCarousel: some View {
        let images = merchant.images ?? []
        
        return VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                        FielmedinaImage(url: image.image?.url ?? image.imageMobile?.url, contentMode: .fill)
                            .containerRelativeFrame(.horizontal)
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(maxHeight: 450)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .scrollTransition(.animated, axis: .horizontal) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1 : 0.9)
                                    .blur(radius: phase.isIdentity ? 0 : 2)
                            }
                            .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selectedImageIndex)
            .contentMargins(.horizontal, 16, for: .scrollContent)
            
            if images.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<images.count, id: \.self) { index in
                        Circle()
                            .fill(index == (selectedImageIndex ?? 0)
                                  ? Color(red: 0.72, green: 0.41, blue: 0.25)
                                  : Color.secondary.opacity(0.35))
                            .frame(width: 6, height: 6)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func detailBadge(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Label(value, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func formatTime(_ timeString: String) -> String {
        let parts = timeString.split(separator: ":")
        if parts.count >= 2 {
            return "\(parts[0]):\(parts[1])"
        }
        return timeString
    }

    private func startNavigation() {
        guard let userCoordinate = locationManager.userLocation else {
            showLocationAlert = true
            return
        }
        
        guard let latitude = merchant.latitude, let longitude = merchant.longitude else {
            navigationErrorMessage = String(localized: "This merchant does not have a location set.")
            showNavigationErrorAlert = true
            return
        }

        // 1. Show loader immediately
        isNavigationLoading = true
        isNavigationPresented = true

        let origin = CLLocationCoordinate2D(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        let destination = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let options = NavigationRouteOptions(coordinates: [origin, destination])
        options.profileIdentifier = .walking

        Task {
            do {
                let routingProvider = await MainActor.run { MapboxNavigationProviderStore.routingProvider() }
                let response = try await routingProvider.calculateRoutes(options: options).value
                
                await MainActor.run {
                    navigationRoutes = response
                    // isNavigationLoading will be set to false by NavigationCoverView when Mapbox is ready
                }
            } catch {
                await MainActor.run {
                    navigationErrorMessage = error.localizedDescription
                    showNavigationErrorAlert = true
                    isNavigationLoading = false
                    isNavigationPresented = false // Dismiss loader on error
                }
            }
        }
    }
}

private struct NavigationCoverView: View {
    @Binding var routes: NavigationRoutes?
    let provider: MapboxNavigationProvider
    let locationName: String
    let userLocation: CLLocationCoordinate2D?
    @Binding var isLoading: Bool
    let onDismiss: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            if let routes = routes {
                MapboxNavigationView(
                    navigationRoutes: routes,
                    mapboxNavigationProvider: provider,
                    userLocation: userLocation,
                    onReady: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isLoading = false
                        }
                    },
                    onDismiss: onDismiss
                )
                .ignoresSafeArea()
            } else {
                Color(red: 0.72, green: 0.41, blue: 0.25)
                    .ignoresSafeArea()
            }
            
            if isLoading || routes == nil {
                ZStack {
                    Color(red: 0.72, green: 0.41, blue: 0.25)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 4)
                                .frame(width: 58, height: 58)
                            
                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 58, height: 58)
                                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                        }
                        .onAppear {
                            isAnimating = true
                        }
                        
                        VStack(spacing: 8) {
                            Text("Preparing navigation to")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.8))
                            
                            Text(locationName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }
                }
                .transition(.opacity)
            }
        }
    }
}
