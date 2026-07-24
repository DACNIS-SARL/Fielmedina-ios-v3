//
//  InlineFilterChip.swift
//  Fielmedina
//
//  Capsule filter button (fixed label + icon) that opens a dropdown menu of
//  options with a checkmark on the active one. Styled like the original Filter
//  button; tints to the accent colour while a filter is applied.
//

import SwiftUI

struct FilterMenuOption: Hashable {
    /// nil represents the "All …" reset option.
    let id: String?
    let label: String

    var identityKey: String { id ?? "__all__" }
}

struct InlineFilterChip: View {
    let icon: String
    let title: LocalizedStringKey
    let options: [FilterMenuOption]
    let selectedId: String?
    let onSelect: (String?) -> Void

    private var isActive: Bool { selectedId != nil }

    var body: some View {
        Menu {
            ForEach(options, id: \.identityKey) { option in
                Button {
                    onSelect(option.id)
                } label: {
                    if selectedId == option.id {
                        Label(option.label, systemImage: "checkmark")
                    } else {
                        Text(option.label)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(isActive ? Color.accentColor : Color.primary)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
