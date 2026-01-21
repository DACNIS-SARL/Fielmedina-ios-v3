//
//  TipsCarousel.swift
//  Fielmedina
//
//  Created by Aslan on 1/21/26.
//

import SwiftUI
struct TipItem: Identifiable {
    let id = UUID()
    let text: String
}

let sampleTips: [TipItem] = [
    TipItem(text: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s"),
    TipItem(text: "Swipe to see more tips. This component uses SwiftUI's TabView for native paging behavior."),
    TipItem(text: "You can customize the background color, font styles, and padding to match your app's design."),
    TipItem(text: "The page indicator dots are custom-built to sit inside the card view."),
    TipItem(text: "This code is ready to be dropped into your iOS 18+ project.")
]

struct HacksAndTipsView: View {
    @State private var currentPageIndex = 0
    let cardBackgroundColor = Color(red: 168/255, green: 108/255, blue: 82/255)
    let mainBackgroundColor = Color(red: 242/255, green: 242/255, blue: 242/255)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Hacks and tips")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 24)
            
            ZStack(alignment: .bottom) {
                TabView(selection: $currentPageIndex) {
                    ForEach(0..<sampleTips.count, id: \.self) { index in
                        VStack {
                            Text(sampleTips[index].text)
                                .font(.body)
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
                    ForEach(0..<sampleTips.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPageIndex ? Color.white : Color.white.opacity(0.4))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentPageIndex)
                    }
                }
                .padding(.bottom, 24)
            }
            .frame(height: 240)
            .background(cardBackgroundColor)
            .cornerRadius(20)
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .padding(.top, 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(mainBackgroundColor)
        .ignoresSafeArea()
    }
}


#Preview {
    HacksAndTipsView()
}
