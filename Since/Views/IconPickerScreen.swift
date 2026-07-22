//
//  IconPickerScreen.swift
//  Since
//

import SwiftUI

private struct IconPage: Identifiable {
    let id: String
    let name: String
    let symbolNames: [String]
}

struct IconPickerScreen: View {
    @Binding var selection: String
    var tintColor: Color

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var selectedPageID = IconPickerScreen.suggestedPageID

    private static let suggestedPageID = "suggested"

    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 12)]

    private var pages: [IconPage] {
        [IconPage(id: Self.suggestedPageID, name: "Suggested", symbolNames: TrackerIconCatalog.suggested)]
            + TrackerIconCatalog.categories.map { IconPage(id: $0.id, name: $0.name, symbolNames: $0.symbolNames) }
    }

    private var searchResults: [String]? {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : TrackerIconCatalog.search(query)
    }

    var body: some View {
        Group {
            if let searchResults, searchResults.isEmpty {
                ContentUnavailableView.search(text: query)
            } else if let searchResults {
                ScrollView {
                    grid(for: searchResults)
                        .padding(.horizontal)
                }
            } else {
                VStack(spacing: 0) {
                    categoryTabStrip
                    TabView(selection: $selectedPageID) {
                        ForEach(pages) { page in
                            ScrollView {
                                grid(for: page.symbolNames)
                                    .padding(.horizontal)
                            }
                            .tag(page.id)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
        }
        .navigationTitle("Choose Icon")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search icons")
    }

    private var categoryTabStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(pages) { page in
                        tabButton(for: page)
                            .id(page.id)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(.bar)
            .accessibilityIdentifier("CategoryTabStrip")
            .onChange(of: selectedPageID) { _, newValue in
                withAnimation {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    private func tabButton(for page: IconPage) -> some View {
        let isSelected = page.id == selectedPageID
        return Button {
            withAnimation {
                selectedPageID = page.id
            }
        } label: {
            Text(page.name)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundStyle(isSelected ? .white : .primary)
                .background(Capsule().fill(isSelected ? tintColor : Color.secondary.opacity(0.15)))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
