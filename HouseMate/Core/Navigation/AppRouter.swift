//
//  AppRouter.swift
//  HouseMate
//

import Observation

@MainActor
@Observable
final class AppRouter {

    var path: [MainRoute] = []

    func navigate(to route: MainRoute) {
        path.append(route)
    }

    func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func reset() {
        path.removeAll()
    }
}
