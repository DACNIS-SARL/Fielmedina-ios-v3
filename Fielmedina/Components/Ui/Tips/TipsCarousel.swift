//
//  TipsCarousel.swift
//  Fielmedina
//
//  Created by Aslan on 1/21/26.
//

import SwiftUI

struct TipsCarousel: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var tips: [Tip] = []
    @State private var isLoading = true
    @State private var currentPageIndex = 0
    
    private var cardHeight: CGFloat {
        sizeClass == .regular ? 400 : 260
    }
    
    private var tipFont: Font {
        sizeClass == .regular ? .largeTitle : .title3
    }
    
    private var headerFont: Font {
        sizeClass == .regular ? .title2 : .subheadline
    }
    
    private var cardGradient: LinearGradient {
        LinearGradient(
            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        Group {
            if isLoading {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray5))
                    .frame(height: cardHeight)
                    .padding(.horizontal, 24)
                    .redacted(reason: .placeholder)
            } else if tips.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hacks and tips")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    ZStack(alignment: .bottom) {
                        TabView(selection: $currentPageIndex) {
                            ForEach(Array(tips.enumerated()), id: \.element.id) { index, tip in
                                ZStack {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: sizeClass == .regular ? 200 : 140))
                                        .foregroundColor(.white.opacity(0.1))
                                        .offset(x: sizeClass == .regular ? 150 : 100, y: sizeClass == .regular ? 50 : 30)
                                        .rotationEffect(.degrees(-15))
                                    
                                    VStack(alignment: .leading, spacing: 12) {
                                        Spacer()
                                        
                                        HStack(spacing: 6) {
                                            Image(systemName: "sparkles")
                                            Text("Did you know?")
                                        }
                                        .font(headerFont)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white.opacity(0.9))
                                        
                                        HTMLTextView(
                                            html: tip.displayDescription,
                                            textStyle: sizeClass == .regular ? .largeTitle : .title3,
                                            textColor: .white,
                                            linkColor: .white,
                                            isBold: true,
                                            lineLimit: 3
                                        )
                                        .minimumScaleFactor(0.5)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, sizeClass == .regular ? 60 : 24)
                                    .padding(.bottom, 40)
                                }
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        
                        HStack(spacing: 8) {
                            ForEach(0..<tips.count, id: \.self) { index in
                                Capsule()
                                    .fill(index == currentPageIndex ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: index == currentPageIndex ? 20 : 6, height: 6)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPageIndex)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .frame(height: cardHeight)
                    .background(cardGradient)
                    .cornerRadius(24)
                    .padding(.horizontal)
                }
            }
        }
        .task {
            await loadTips()
        }
    }
    
    private func loadTips() async {
        isLoading = true
        do {
            tips = try await TipService.shared.fetchTips(limit: 10)
        } catch {
            tips = []
        }
        isLoading = false
    }
}

#Preview {
    TipsCarousel()
}
