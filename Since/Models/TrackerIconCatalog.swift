//
//  TrackerIconCatalog.swift
//  Since
//

import Foundation

struct SymbolCategory: Identifiable {
    let id: String
    let name: String
    let symbolNames: [String]
}

private struct CatalogSymbol: Decodable {
    let name: String
    let categories: [String]
    let keywords: [String]
}

private struct CatalogCategoryDefinition: Decodable {
    let id: String
    let name: String
}

private struct Catalog: Decodable {
    let categories: [CatalogCategoryDefinition]
    let symbols: [CatalogSymbol]
}

enum TrackerIconCatalog {
    /// The original curated pool from the SIN-5 picker POC, shown as the picker's first
    /// "Suggested" section. Intentionally unchanged so existing trackers' icons and the
    /// default icon for new trackers (`TrackerIcon.curated[0]`) keep behaving identically.
    static let suggested: [String] = TrackerIcon.curated

    /// Bundled from `SFSymbolsCatalog.json`, which is generated (not hand-curated) from
    /// Apple's own SF Symbols name/category/keyword metadata, covering every symbol name
    /// available on this OS. A symbol without any real category (after excluding the SF
    /// Symbols app's internal filter categories like "whatsnew"/"multicolor") falls back to
    /// the "Other" bucket rather than being dropped.
    static let categories: [SymbolCategory] = {
        var symbolNamesByCategory: [String: [String]] = [:]
        for symbol in rawCatalog.symbols {
            for categoryID in Set(symbol.categories) {
                symbolNamesByCategory[categoryID, default: []].append(symbol.name)
            }
        }
        return rawCatalog.categories.compactMap { definition in
            guard let symbolNames = symbolNamesByCategory[definition.id] else { return nil }
            return SymbolCategory(id: definition.id, name: definition.name, symbolNames: symbolNames)
        }
    }()

    private static let keywordsByName: [String: [String]] = {
        Dictionary(uniqueKeysWithValues: rawCatalog.symbols.map { ($0.name, $0.keywords) })
    }()

    private static let rawCatalog: Catalog = {
        guard let url = Bundle.main.url(forResource: "SFSymbolsCatalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(Catalog.self, from: data) else {
            fatalError("SFSymbolsCatalog.json is missing or malformed")
        }
        return catalog
    }()

    /// Substring match (case-insensitive) against a symbol's own name, its category's display
    /// name, or any of its Apple-provided search keywords. Results preserve catalog order and
    /// are deduplicated (a symbol can appear in more than one category).
    static func search(_ query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }

        let matchingCategoryIDs = Set(categories.filter { $0.name.lowercased().contains(trimmed) }.map(\.id))

        var seen = Set<String>()
        var results: [String] = []
        for category in categories {
            for name in category.symbolNames where !seen.contains(name) {
                let matches = matchingCategoryIDs.contains(category.id)
                    || name.lowercased().contains(trimmed)
                    || (keywordsByName[name]?.contains { $0.lowercased().contains(trimmed) } ?? false)
                if matches {
                    seen.insert(name)
                    results.append(name)
                }
            }
        }

        return results
    }
}
