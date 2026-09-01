//
//  View+EXT.swift
//  HouseMate
//
//  Created by Marcin Turek on 18/08/2026.
//

import SwiftUI

extension View {
    func customTabBarSafeArea() -> some View {
        self
            .toolbarVisibility(.hidden, for: .tabBar)
            .safeAreaBar(edge: .bottom, spacing: 0) {
                Text(".")
                    .blendMode(.destinationOver)
                    .frame(height: 55)
            }
    }
}



extension View {
    @ViewBuilder
    func blurFade(_ status: Bool) -> some View {
        self
            .compositingGroup()
            .blur(radius: status ? 0 : 10)
            .opacity(status ? 1 : 0)
    }

    func roundedSwipeActions(cornerRadius: CGFloat = 22) -> some View {
        let shape = RoundedRectangle(
            cornerRadius: cornerRadius,
            style: .continuous
        )

        return containerShape(shape)
            .clipShape(shape)
    }
}
