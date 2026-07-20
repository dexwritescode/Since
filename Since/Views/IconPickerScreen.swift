//
//  IconPickerScreen.swift
//  Since
//

import SwiftUI

struct IconPickerScreen: View {
    @Binding var selection: String
    var tintColor: Color

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 12)]

    private var searchResults: [String]? {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : TrackerIconCatalog.search(query)
    }

    var body: some View {
        Group {
            if let searchResults, searchResults.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                List {
                    if let searchResults {
                        Section {
                            grid(for: searchResults)
                        }
                    } else {
                        Section("Suggested") {
                            grid(for: TrackerIconCatalog.suggested)
                        }
                        ForEach(TrackerIconCatalog.categories) { category in
                            Section(category.name) {
                                grid(for: category.symbolNames)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Choose Icon")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search icons")
    }

    @ViewBuilder
    private func grid(for symbolNames: [String]) -> some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(symbolNames, id: \.self) { name in
                IconGridButton(symbolName: name, isSelected: name == selection, tintColor: tintColor) {
                    selection = name
                    dismiss()
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    @Previewable @State var selection = "flame.fill"
    return NavigationStack {
        IconPickerScreen(selection: $selection, tintColor: .orange)
    }
}
