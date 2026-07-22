//
//  IconPickerView.swift
//  Since
//

import SwiftUI

enum TrackerIcon {
    /// Curated pool shown as the "Suggested" section atop the full icon picker
    /// (see IconPickerScreen / TrackerIconCatalog).
    static let curated: [String] = [
        "flame.fill",
        "drop.fill",
        "leaf.fill",
        "moon.stars.fill",
        "heart.fill",
        "bolt.fill",
        "cup.and.saucer.fill",
        "figure.walk",
        "figure.run",
        "book.fill",
        "bed.double.fill",
        "gamecontroller.fill",
        "phone.fill",
        "fork.knife",
        "pills.fill",
        "checkmark.seal.fill",
        "star.fill",
        "sun.max.fill",
        "cloud.fill",
        "house.fill",
        "calendar",
        "clock.fill",
        "bell.fill",
        "target",
        "dollarsign.circle.fill",
    ]
}

struct IconGridButton: View {
    let symbolName: String
    let isSelected: Bool
    var tintColor: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.title2)
                .frame(width: 44, height: 44)
                .foregroundStyle(isSelected ? .white : tintColor)
                .background(
                    Circle()
                        .fill(isSelected ? tintColor : tintColor.opacity(0.15))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbolName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var selection = "flame.fill"
    return LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 12)], spacing: 12) {
        ForEach(TrackerIcon.curated, id: \.self) { icon in
            IconGridButton(symbolName: icon, isSelected: icon == selection, tintColor: .orange) {
                selection = icon
            }
        }
    }
    .padding()
}
