//
//  DeepLinkEventDetailView.swift
//  Fielmedina
//
//  Created by Aslan on 3/13/26.
//

import SwiftUI

struct DeepLinkEventDetailView: View {
    let eventId: String
    
    @State private var event: Event?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if let event {
                EventDetailView(event: event)
            } else if isLoading {
                EventDetailSkeleton()
                    .ignoresSafeArea(edges: .top)
            } else if let errorMessage {
                errorView(message: errorMessage)
            }
        }
        .task {
            await fetchEvent()
        }
    }
    
    private func fetchEvent() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetched = try await EventService.shared.fetchEvent(id: eventId)
            await MainActor.run {
                self.event = fetched
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                LogUtils.e("DeepLinkEventDetail", "Failed to fetch event \(eventId): \(error.localizedDescription)")
            }
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("Unable to load event")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                Task { await fetchEvent() }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.72, green: 0.41, blue: 0.25))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Skeleton shimmer for event detail while loading
private struct EventDetailSkeleton: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Hero placeholder
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 320)
                    .shimmer()
                
                // Details card placeholder
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 200, height: 24)
                        .shimmer()
                    
                    // Date row
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 20, height: 20)
                            .shimmer()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(width: 150, height: 16)
                            .shimmer()
                    }
                    
                    // Info badges
                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray5))
                            .frame(width: 100, height: 40)
                            .shimmer()
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray5))
                            .frame(width: 100, height: 40)
                            .shimmer()
                    }
                    
                    // Description lines
                    ForEach(0..<5, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 14)
                            .shimmer()
                    }
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 180, height: 14)
                        .shimmer()
                }
                .padding(20)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(.top, -24)
            }
        }
    }
}

/// Simple shimmer modifier
private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.3), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 300
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

private extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
