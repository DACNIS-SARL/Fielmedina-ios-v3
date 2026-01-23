//
//  MapFilterSheet.swift
//  Fielmedina
//
//  Created by Aslan on 1/23/26.
//

import SwiftUI

struct MapFilterSheet: View {
    let categories: [LocationCategory]
    @Binding var selectedCategoryIds: Set<String>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(categories) { category in
                        Toggle(isOn: binding(for: category.id)) {
                            Text(category.displayName)
                        }
                    }
                }
            }
            .navigationTitle("Filter")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        selectedCategoryIds = Set(categories.map { $0.id })
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func binding(for categoryId: String) -> Binding<Bool> {
        Binding(
            get: { selectedCategoryIds.contains(categoryId) },
            set: { isSelected in
                if isSelected {
                    selectedCategoryIds.insert(categoryId)
                } else {
                    selectedCategoryIds.remove(categoryId)
                }
            }
        )
    }
}

#Preview {
    MapFilterSheet(
        categories: [
            LocationCategory(id: "1", nameEn: "Location", nameFr: "Lieu"),
            LocationCategory(id: "2", nameEn: "Mosque", nameFr: "Mosquee")
        ],
        selectedCategoryIds: .constant(["1", "2"])
    )
}
