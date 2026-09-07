//
//  HapticFeedback.swift
//  HouseMate
//

import UIKit

@MainActor
enum HapticFeedback {

    static func validationError() {
        UINotificationFeedbackGenerator()
            .notificationOccurred(.error)
    }

    static func actionSuccess() {
        UINotificationFeedbackGenerator()
            .notificationOccurred(.success)
    }
}
