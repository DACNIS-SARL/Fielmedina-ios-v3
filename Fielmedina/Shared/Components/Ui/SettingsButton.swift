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
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsButton()
    }
}
