//
//  AppRouter.swift
//  HouseMate
//

import Observation
import SwiftUI

@MainActor
@Observable
final class AppRouter {

    var path = NavigationPath()

    func navigate(
        to route: MainRoute,
        trackInteraction: Bool = true
    ) {
        if trackInteraction {
        }
        path.append(route)
    }

    func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func reset() {
        path = NavigationPath()
    }
}
