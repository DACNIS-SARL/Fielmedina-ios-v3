//
//  SettingsButton.swift
//  Fielmedina
//
//  Created by Aslan on 1/15/26.
//

import SwiftUI

/// Publishes the settings button's on-screen frame so the onboarding coachmark can
/// highlight it precisely, instead of guessing at a hardcoded position. Mirrors what
/// Android does with `onGloballyPositioned` + `boundsInRoot()`.
struct SettingsButtonFrameKey: PreferenceKey {
    static let defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        // Keep the last real measurement; ignore empty defaults from sibling views.
        if next != .zero { value = next }
    }
}

struct SettingsButton: View {
    var body: some View {
        NavigationLink {
            SettingsView()
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.primary)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: SettingsButtonFrameKey.self,
                    value: geo.frame(in: .global)
                )
            }
        )
    }
}

#Preview {
    NavigationStack {
        SettingsButton()
    }
}
