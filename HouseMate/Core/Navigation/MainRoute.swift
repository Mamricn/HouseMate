//
//  MainRoute.swift
//  HouseMate
//

import Foundation

/// Screens presented by the main application navigation stack.
///
/// Modal forms stay modelled as sheets. Add a case here when a screen is part
/// of a navigation flow or must be reachable from a deep link.
enum MainRoute: Hashable {
    case settings
    case householdSettings
    case accountSettings
}
