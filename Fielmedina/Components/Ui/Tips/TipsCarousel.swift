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
        sizeClass == .regular ? 340 : 240
    }
    
    private var tipFont: Font {
        sizeClass == .regular ? .title2 : .body
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
                                VStack {
                                    Text(tip.displayDescription.htmlToMarkdown())
                                        .font(tipFont)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                        .padding(.top, 32)
                                        .padding(.horizontal, 24)
                                        .padding(.bottom, 60)
                                    Spacer()
                                }
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        
                        HStack(spacing: 8) {
                            ForEach(0..<tips.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentPageIndex ? Color.white : Color.white.opacity(0.4))
                                    .frame(width: 8, height: 8)
                                    .animation(.easeInOut(duration: 0.3), value: currentPageIndex)
                            }
                        }
                        .padding(.bottom, 24)
                    }
                    .frame(height: cardHeight)
                    .background(Color.accentColor)
                    .cornerRadius(20)
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
