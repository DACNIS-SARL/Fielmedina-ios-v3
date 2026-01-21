//
//  SettingsButton.swift
//  Fielmedina
//
//  Created by Aslan on 1/15/26.
//

import SwiftUI

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
    }
}

#Preview {
    NavigationStack {
        SettingsButton()
    }
}
