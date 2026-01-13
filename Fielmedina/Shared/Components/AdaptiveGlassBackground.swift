//
//  AdaptiveGlassBackground.swift
//  Fielmedina
//
//  Created by Aslan on 1/13/26.
//

import SwiftUI

extension View {
    func adaptiveGlassBackground(color: Color) -> some View {
        self.background {
            if #available(iOS 19.0, *) {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 0.5))
            } else {
                Capsule()
                    .fill(color)
            }
        }
    }
}
