//
//  ButtonStyle.swift
//  Fielmedina
//
//  Created by Aslan on 1/13/26.
//

import SwiftUI

struct CustomButtonStyle: SwiftUI.ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .foregroundStyle(colorScheme == .dark ? .white : .accentColor)
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(.ultraThinMaterial)
            .clipShape(.rect(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
