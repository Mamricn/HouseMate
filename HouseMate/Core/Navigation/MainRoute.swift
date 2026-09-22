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
    case profileSettings
    case householdBills
    case householdCleaning
    case householdShopping
    case householdPolls
    case householdReminders(UUID)
    case householdDocuments

    var analyticsName: String {
        switch self {
        case .settings: "settings"
        case .householdSettings: "household_settings"
        case .accountSettings: "account_settings"
        case .profileSettings: "profile_settings"
        case .householdBills: "bills"
        case .householdCleaning: "cleaning"
        case .householdShopping: "shopping"
        case .householdPolls: "polls"
        case .householdReminders: "reminders"
        case .householdDocuments: "documents"
        }
    }
}
