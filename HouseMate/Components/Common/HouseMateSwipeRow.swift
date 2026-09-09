//
//  HouseMateSwipeRow.swift
//  HouseMate
//

import SwiftUI
import UIKit

struct HouseMateSwipeAction {
    let accessibilityLabel: String
    let systemImage: String
    let color: Color
    let action: () -> Void
}

struct HouseMateSwipeRow<Content: View>: View {

    let leadingAction: HouseMateSwipeAction?
    let trailingAction: HouseMateSwipeAction?
    @ViewBuilder let content: () -> Content

    @State private var restingOffset: CGFloat = 0
    @State private var currentOffset: CGFloat = 0

    private let revealWidth: CGFloat = 64
    private let actionSize: CGFloat = 44

    private var offset: CGFloat {
        currentOffset
    }

    var body: some View {
        ZStack {
            actionsBackground

            content()
                .contentShape(Rectangle())
                .offset(x: offset)
                .onTapGesture {
                    closeActions()
                }
        }
        .contentShape(Rectangle())
        .clipped()
        .gesture(horizontalPanGesture)
    }

    private var actionsBackground: some View {
        HStack(spacing: 0) {
            actionContainer(
                action: leadingAction,
                visibleWidth: max(offset, 0),
                alignment: .leading
            )

            Spacer(minLength: 0)

            actionContainer(
                action: trailingAction,
                visibleWidth: max(-offset, 0),
                alignment: .trailing
            )
        }
    }

    private func actionContainer(
        action: HouseMateSwipeAction?,
        visibleWidth: CGFloat,
        alignment: Alignment
    ) -> some View {
        ZStack(alignment: alignment) {
            if let action {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    action.action()
                    closeActions()
                } label: {
                    Image(systemName: action.systemImage)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: actionSize, height: actionSize)
                        .background(action.color, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(action.accessibilityLabel)
                .padding(.horizontal, 6)
                .scaleEffect(min(max(visibleWidth / revealWidth, 0.75), 1))
                .opacity(min(visibleWidth / 20, 1))
            }
        }
        .frame(width: visibleWidth, alignment: alignment)
        .clipped()
    }

    private var horizontalPanGesture: HorizontalPanGesture {
        HorizontalPanGesture { translation in
            currentOffset = clamped(restingOffset + translation)
        } onEnded: { translation, velocity in
            let predictedOffset = clamped(
                restingOffset + translation + velocity * 0.16
            )
            let destination: CGFloat

            if predictedOffset > revealWidth * 0.45, leadingAction != nil {
                destination = revealWidth
            } else if predictedOffset < -revealWidth * 0.45, trailingAction != nil {
                destination = -revealWidth
            } else {
                destination = 0
            }

            withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.86)) {
                restingOffset = destination
                currentOffset = destination
            }
        }
    }

    private func clamped(_ proposedOffset: CGFloat) -> CGFloat {
        let minimumOffset = trailingAction == nil ? 0 : -revealWidth
        let maximumOffset = leadingAction == nil ? 0 : revealWidth
        return min(max(proposedOffset, minimumOffset), maximumOffset)
    }

    private func closeActions() {
        guard restingOffset != 0 else { return }

        withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.86)) {
            restingOffset = 0
            currentOffset = 0
        }
    }
}

private struct HorizontalPanGesture: UIGestureRecognizerRepresentable {

    let onChanged: (CGFloat) -> Void
    let onEnded: (CGFloat, CGFloat) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer()
        recognizer.delegate = context.coordinator
        recognizer.cancelsTouchesInView = false
        recognizer.maximumNumberOfTouches = 1
        return recognizer
    }

    func updateUIGestureRecognizer(
        _ recognizer: UIPanGestureRecognizer,
        context: Context
    ) {}

    func handleUIGestureRecognizerAction(
        _ recognizer: UIPanGestureRecognizer,
        context: Context
    ) {
        let translation = recognizer.translation(in: recognizer.view).x

        switch recognizer.state {
        case .began, .changed:
            onChanged(translation)
        case .ended:
            onEnded(
                translation,
                recognizer.velocity(in: recognizer.view).x
            )
        case .cancelled, .failed:
            onEnded(translation, 0)
        default:
            break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {

        func gestureRecognizerShouldBegin(
            _ gestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
                return true
            }

            let velocity = panGesture.velocity(in: panGesture.view)
            return abs(velocity.x) > abs(velocity.y)
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}
