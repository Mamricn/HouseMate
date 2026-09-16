import SwiftUI

extension View {
    func houseMatePullToRefresh(
        indicatorTopPadding: CGFloat = 8,
        action: @escaping @MainActor () async -> Void
    ) -> some View {
        modifier(
            HouseMatePullToRefreshModifier(
                indicatorTopPadding: indicatorTopPadding,
                action: action
            )
        )
    }
}

private struct HouseMatePullToRefreshModifier: ViewModifier {
    let indicatorTopPadding: CGFloat
    let action: @MainActor () async -> Void

    @State private var pullDistance: CGFloat = 0
    @State private var isRefreshing = false
    @State private var isArmed = false
    @State private var hasTriggered = false

    private let threshold: CGFloat = 72

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                indicator
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                max(
                    0,
                    -(geometry.contentOffset.y + geometry.contentInsets.top)
                )
            } action: { previousDistance, currentDistance in
                pullDistance = currentDistance

                if currentDistance < 4, !isRefreshing {
                    isArmed = false
                    hasTriggered = false
                }

                if currentDistance >= threshold,
                   !isArmed,
                   !hasTriggered,
                   !isRefreshing {
                    isArmed = true
                    HapticFeedback.selection()
                }

                if previousDistance >= threshold,
                   currentDistance < threshold,
                   isArmed,
                   !hasTriggered,
                   !isRefreshing {
                    isArmed = false
                    hasTriggered = true
                    refresh()
                }
            }
    }

    private var indicator: some View {
        let progress = min(pullDistance / threshold, 1)

        return ZStack {
            Image(systemName: "house.fill")
                .foregroundStyle(.secondary.opacity(0.55))

            Image(systemName: "house.fill")
                .foregroundStyle(.blue)
                .mask(alignment: .bottom) {
                    Rectangle()
                        .scaleEffect(
                            y: isRefreshing ? 1 : progress,
                            anchor: .bottom
                        )
                }
                .symbolEffect(.bounce, value: isArmed)
                .symbolEffect(
                    .pulse,
                    options: .repeating,
                    isActive: isRefreshing
                )
        }
        .font(.system(size: 18, weight: .semibold))
        .frame(width: 22, height: 22)
        .scaleEffect(isRefreshing ? 1 : 0.78 + progress * 0.22)
        .padding(9)
        .background(.ultraThinMaterial, in: Circle())
        .opacity(pullDistance > 8 || isRefreshing ? 1 : 0)
        .offset(y: indicatorTopPadding)
        .animation(.easeOut(duration: 0.18), value: pullDistance)
        .animation(.easeInOut(duration: 0.2), value: isRefreshing)
        .animation(.snappy(duration: 0.24), value: isArmed)
        .allowsHitTesting(false)
    }

    private func refresh() {
        isRefreshing = true

        Task { @MainActor in
            await action()
            isRefreshing = false
        }
    }
}
