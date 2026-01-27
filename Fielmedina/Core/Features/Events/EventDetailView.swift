//
//  EventDetailView.swift
//  Fielmedina
//
//  Created by Aslan on 1/23/26.
//

import SwiftUI

struct EventDetailView: View {
    let event: Event
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                HeroBanner(
                    imageURL: event.imageURL,
                    showText: false
                )
                .frame(maxWidth: .infinity)

                detailsCard
            }
            .frame(maxWidth: .infinity)
        }
        .coordinateSpace(name: "scroll")
        .ignoresSafeArea(edges: .top)
        .ignoresSafeArea(edges: .horizontal)
        .navigationTitle(event.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SettingsButton()
            }
        }
        .safeAreaInset(edge: .bottom) {
            reserveButton
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
        }
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(event.displayName)
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            AdsCarousel()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)

            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                Text(event.displayDateFormatted)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                detailBadge(title: String(localized: "Hours"), value: formattedTime)
                detailBadge(title: String(localized: "Admission Fee"), value: event.displayPrice)
            }

            if let description = event.displayDescription {
                Text(description.htmlToMarkdown())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 0)
        .padding(.top, -24)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }

    private var reserveButton: some View {
        Button {
            FirebaseUtils.trackButtonTap(buttonName: "event_reserve_spot", screenName: "EventDetail")
            openEventLink()
        } label: {
            Text("Reserve Your Spot")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func openEventLink() {
        guard let link = event.resolvedLink, let url = URL(string: link) else {
            return
        }
        openURL(url)
    }

    private func detailBadge(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Label(value, systemImage: title == String(localized: "Hours") ? "clock" : "dollarsign.circle")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var formattedTime: String {
        guard let time = event.time else { return "--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        if let date = formatter.date(from: time) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }
        formatter.dateFormat = "HH:mm"
        if formatter.date(from: time) != nil {
            return time
        }
        return time
    }
}

//#Preview {
//    EventDetailView(event: Event.sampleEvents[0])
//}
