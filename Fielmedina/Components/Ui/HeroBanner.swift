//
//  HeroBanner.swift
//  Fielmedina
//
//  Created by Aslan on 1/15/26.
//

import SwiftUI

struct HeroBanner: View {
    let imageName: String
    let imageURL: String?
    let showText: Bool
    let primaryText: LocalizedStringResource?
    let secondaryText: LocalizedStringResource?
    let height: CGFloat
    
    init(
        imageName: String = "hero-bg",
        imageURL: String? = nil,
        showText: Bool = true,
        primaryText: LocalizedStringResource? = "hero_tunisia_title",
        secondaryText: LocalizedStringResource? = "hero_welcome_subtitle",
        height: CGFloat = 320
    ) {
        self.imageName = imageName
        self.imageURL = imageURL
        self.showText = showText
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.height = height
    }
    
    var body: some View {
        GeometryReader { geo in
            let offset = geo.frame(in: .named("scroll")).minY
            let dynamicHeight = height + max(0, offset)
            
            ZStack(alignment: .bottom) {
                Group {
                    if let imageURL {
                        FielmedinaImage(url: imageURL, contentMode: .fill)
                    } else {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                    }
                }
                .frame(width: geo.size.width, height: dynamicHeight)
                .clipped()
                
                
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.5),
                        Color.clear,
                        Color.black.opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: geo.size.width, height: dynamicHeight)
                
                
                if showText {
                    VStack(alignment: .leading, spacing: -4) {
                        if let primary = primaryText {
                            Text(primary)
                                .font(.system(size: 72, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.95)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 2)
                                .minimumScaleFactor(0.3)
                                .lineLimit(1)
                        }
                        
                        if let secondary = secondaryText {
                            Text(secondary)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 1)
                                .padding(.leading, 4)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(width: geo.size.width, height: dynamicHeight, alignment: .bottom)
            .offset(y: -max(0, offset))
        }
        .frame(height: height)
    }
}

#Preview("Default (With Text)") {
    ScrollView {
        VStack(spacing: 0) {
            HeroBanner()
            
            VStack(spacing: 20) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 100)
                        .padding(.horizontal)
                        .overlay(
                            Text("Content \(index + 1)")
                                .font(.headline)
                        )
                }
            }
            .padding(.top, 20)
        }
    }
    .coordinateSpace(name: "scroll")
    .ignoresSafeArea()
}

#Preview("No Text") {
    ScrollView {
        VStack(spacing: 0) {
            HeroBanner(
                imageName: "hero-bg",
                showText: false
            )
            
            VStack(spacing: 20) {
                Text("Content Below Banner")
                    .font(.title)
                    .padding()
            }
        }
    }
    .coordinateSpace(name: "scroll")
    .ignoresSafeArea()
}

#Preview("Custom Text & Image") {
    ScrollView {
        VStack(spacing: 0) {
            HeroBanner(
                imageName: "custom-image",
                showText: true,
                primaryText: "Explore",
                secondaryText: "the beauty"
            )
            
            VStack(spacing: 20) {
                Text("Custom Content")
                    .font(.title)
                    .padding()
            }
        }
    }
    .coordinateSpace(name: "scroll")
    .ignoresSafeArea()
}

#Preview("Smaller Height") {
    ScrollView {
        VStack(spacing: 0) {
            HeroBanner(
                imageName: "hero-bg",
                showText: true,
                primaryText: "Quick View",
                secondaryText: nil,
                height: 200
            )
            
            VStack(spacing: 20) {
                Text("Compact Banner")
                    .font(.title)
                    .padding()
            }
        }
    }
    .coordinateSpace(name: "scroll")
    .ignoresSafeArea()
}

#Preview("Landscape", traits: .landscapeLeft) {
    ScrollView {
        VStack(spacing: 0) {
            HeroBanner(
                imageName: "hero-bg",
                showText: true,
                primaryText: "Tunisia",
                secondaryText: "welcome"
            )
            
            VStack(spacing: 20) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 100)
                        .padding(.horizontal)
                        .overlay(
                            Text("Content \(index + 1)")
                                .font(.headline)
                        )
                }
            }
            .padding(.top, 20)
        }
    }
    .coordinateSpace(name: "scroll")
    .ignoresSafeArea()
}
