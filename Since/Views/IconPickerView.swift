//
//  IconPickerView.swift
//  Since
//

import SwiftUI

enum TrackerIcon {
    /// Curated pool for the v1.0 icon picker. A searchable/expanded picker is tracked
    /// separately (SIN-24) since it needs a much larger bundled symbol dataset.
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

struct IconPickerView: View {
    @Binding var selection: String
    var tintColor: Color

    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(TrackerIcon.curated, id: \.self) { icon in
                Button {
                    selection = icon
                } label: {
                    Image(systemName: icon)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .foregroundStyle(icon == selection ? .white : tintColor)
                        .background(
                            Circle()
                                .fill(icon == selection ? tintColor : tintColor.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(icon)
                .accessibilityAddTraits(icon == selection ? .isSelected : [])
            }
        }
    }
}

#Preview {
    @Previewable @State var selection = "flame.fill"
    return IconPickerView(selection: $selection, tintColor: .orange)
        .padding()
}
