//
//  TipItem.swift
//  Fielmedina
//
//  Created by Aslan on 3/18/26.
//

import SwiftUI

struct TipItem: View {
    let tip: Tip
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HTMLTextView(
            html: tip.displayDescription,
            textStyle: .subheadline,
            textColor: Color(.label),
            linkColor: .accentColor,
            isBold: false,
            lineLimit: nil
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            colorScheme == .dark
                ? Color(.systemGray6)
                : Color(.systemBackground)
        )
        .clipShape(.rect(cornerRadius: 16))
        .shadow(
            color: colorScheme == .dark
                ? Color.white.opacity(0.05)
                : Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 2
        )
    }
}
