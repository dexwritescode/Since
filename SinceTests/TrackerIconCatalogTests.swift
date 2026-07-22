//
//  TrackerIconCatalogTests.swift
//  SinceTests
//

import Testing
import UIKit
@testable import Since

struct TrackerIconCatalogTests {
    @Test func everySymbolNameResolvesToAValidSFSymbol() {
        let allNames = Set(TrackerIconCatalog.suggested + TrackerIconCatalog.categories.flatMap(\.symbolNames))
        let invalidNames = allNames.filter { UIImage(systemName: $0) == nil }
        #expect(invalidNames.isEmpty, "Invalid SF Symbol names: \(invalidNames.sorted())")
    }

    @Test func categoriesContainNoDuplicateNamesWithinThemselves() {
        for category in TrackerIconCatalog.categories {
            let unique = Set(category.symbolNames)
            #expect(unique.count == category.symbolNames.count, "Duplicate symbol names in \(category.name)")
        }
    }

    @Test func suggestedMatchesExistingCuratedDefaults() {
        #expect(TrackerIconCatalog.suggested == TrackerIcon.curated)
    }

    @Test func searchWithEmptyQueryReturnsNoResults() {
        #expect(TrackerIconCatalog.search("").isEmpty)
        #expect(TrackerIconCatalog.search("   ").isEmpty)
    }

    @Test func searchMatchesSymbolNameSubstringCaseInsensitively() {
        #expect(TrackerIconCatalog.search("FIGURE.RUN").contains("figure.run"))
        #expect(TrackerIconCatalog.search("figure.run").contains("figure.run"))
    }

    @Test func searchMatchesCategoryNameAsWellAsSymbolName() {
        let results = TrackerIconCatalog.search("Fitness")
        let fitnessCategory = TrackerIconCatalog.categories.first { $0.name == "Fitness" }!
        #expect(Set(fitnessCategory.symbolNames).isSubset(of: Set(results)))
    }

    @Test func searchMatchesAppleProvidedKeywordsNotJustNameOrCategory() {
        // "bird.fill" carries the Apple-provided keyword "animals" but neither its own name
        // nor its category ("Nature") contains that substring.
        #expect(TrackerIconCatalog.search("animals").contains("bird.fill"))
    }

    @Test func searchWithNoMatchesReturnsEmptyArray() {
        #expect(TrackerIconCatalog.search("zzzznonexistentsymbolqqq").isEmpty)
    }

    @Test func searchResultsContainNoDuplicates() {
        let results = TrackerIconCatalog.search("fill")
        #expect(Set(results).count == results.count)
    }

    @Test func everySymbolHasAtLeastOneCategory() {
        let categorized = Set(TrackerIconCatalog.categories.flatMap(\.symbolNames))
        #expect(!categorized.isEmpty)
    }
}
