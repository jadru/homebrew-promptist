//
//  FilterState.swift
//  Promptist
//
//  Encapsulates the 3-axis filter state for the Template Manager.
//  Priority: App Filter → Category Filter → Collection Filter → Search
//

import Foundation

/// Encapsulates the 3-axis filter state for template filtering.
struct FilterState: Equatable {
    /// 1st Priority: App filter (single selection)
    /// When nil and autoDetectedApp is true, uses the detected frontmost app
    var selectedApp: PromptAppFilter?

    /// Whether to automatically use the detected frontmost app
    var autoDetectedApp: Bool = true

    /// 2nd Priority: Category filter
    /// nil = "All Categories"
    var selectedCategoryId: UUID?

    /// 3rd Priority: Collection filter
    /// nil = "All Collections"
    var selectedCollectionId: UUID?

    /// 4th Priority: Search text
    var searchText: String = ""

    /// Whether any filters are currently active
    var hasActiveFilters: Bool {
        selectedApp != nil ||
        !autoDetectedApp ||
        selectedCategoryId != nil ||
        selectedCollectionId != nil ||
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Reset all filters to default state
    mutating func reset() {
        selectedApp = nil
        autoDetectedApp = true
        selectedCategoryId = nil
        selectedCollectionId = nil
        searchText = ""
    }

    /// Reset only the search text
    mutating func clearSearch() {
        searchText = ""
    }
}

// MARK: - Launcher Filter State

/// Simplified filter state for the Launcher (no category filter).
/// Priority: App Filter (auto) → Collection Filter → Search
struct LauncherFilterState: Equatable {
    /// Collection filter (nil = show all, including uncollected)
    var selectedCollectionId: UUID?

    /// Whether currently browsing inside a collection
    var isBrowsingCollection: Bool {
        selectedCollectionId != nil
    }

    /// Search text
    var searchText: String = ""

    /// Reset to default state
    mutating func reset() {
        selectedCollectionId = nil
        searchText = ""
    }
}
