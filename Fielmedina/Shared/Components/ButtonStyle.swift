//
//  ButtonStyle.swift
//  Fielmedina
//
//  Created by Aslan on 1/13/26.
//

import SwiftUI


struct ButtonStyle: SwiftUI.ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.subheadline.bold())
                .foregroundStyle(getTextColor())
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .adaptiveGlassBackground()
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
        }
        private func getTextColor() -> Color {
            if #available(iOS 18.0, *) {
                return colorScheme == .dark ? .white : Color.accentColor
            } else {
                return .white
            }
        }
    }
