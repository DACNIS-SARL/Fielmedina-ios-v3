//
//  InlineFilterChip.swift
//  Fielmedina
//
//  Compact inline filter control (a capsule chip that opens a dropdown menu of
//  options with a checkmark on the active one). Used for the split City / Category
//  filters shown on the list headers.
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
    let options: [FilterMenuOption]
    let selectedId: String?
    let onSelect: (String?) -> Void

    private var selectedLabel: String {
        options.first(where: { $0.id == selectedId })?.label
            ?? options.first?.label
            ?? ""
    }

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
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                Text(selectedLabel)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
