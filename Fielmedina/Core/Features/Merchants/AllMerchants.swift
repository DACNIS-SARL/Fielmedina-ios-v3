import SwiftUI
import CoreLocation

struct AllMerchants: View {
    @State private var model = AllMerchantsModel()
    @State private var locationManager = LocationManager()
    @State private var carouselRefreshTrigger: Int = 0

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    CarouselListMerchants(
                        title: "Top Picks Right Now",
                        isFeaturedOnly: true,
                        refreshTrigger: $carouselRefreshTrigger
                    )

                    HStack(spacing: 8) {
                        InlineFilterChip(
                            icon: "mappin.and.ellipse",
                            title: "Regions",
                            options: model.cityOptions,
                            selectedId: model.selectedCityId
                        ) { model.selectedCityId = $0 }

                        Spacer()

                        InlineFilterChip(
                            icon: "slider.horizontal.3",
                            title: "Filter",
                            options: model.categoryOptions,
                            selectedId: model.selectedCategoryId
                        ) { model.selectedCategoryId = $0 }
                    }
                    .padding(.horizontal, 16)

                    if model.isLoading {
                        VStack(spacing: 12) {
                            ForEach(0..<6, id: \.self) { _ in
                                LocationItemSkeleton()
                            }
                        }
                        .padding(.horizontal, 16)
                    } else if let error = model.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                            Button("Try Again") {
                                Task { await model.loadData() }
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .padding(.horizontal)
                    } else if model.displayedMerchants.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "storefront")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)

                            Text(model.emptyStateTitle)
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text(model.emptyStateMessage)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(model.displayedMerchants) { merchant in
                                NavigationLink {
                                    MerchantDetailView(merchant: merchant)
                                } label: {
                                    MerchantItem(merchant: merchant)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(Color(.secondarySystemBackground))
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .task(id: model.merchants.count) {
                                    if model.isNearEnd(merchant) {
                                        await model.loadNextPage()
                                    }
                                }
                                .simultaneousGesture(TapGesture().onEnded {
                                    FirebaseUtils.trackButtonTap(
                                        buttonName: "merchant_item",
                                        screenName: "AllMerchants"
                                    )
                                })
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
                .padding(.top, 12)
            }
            .refreshable {
                carouselRefreshTrigger += 1
                await model.refreshFromNetwork()
            }
        }
        .navigationTitle("Our Picks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SettingsButton()
            }
        }
        .task {
            locationManager.requestPermission()
            locationManager.startUpdatingLocation()
            await model.loadData()
        }
        .onChange(of: locationManager.userLocation?.latitude) { _, _ in
            model.updateUserLocation(locationManager.userLocation)
        }
        .onChange(of: locationManager.userLocation?.longitude) { _, _ in
            model.updateUserLocation(locationManager.userLocation)
        }
    }
}

#Preview {
    AllMerchants()
}
