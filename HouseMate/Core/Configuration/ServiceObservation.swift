//
//  ServiceObservation.swift
//  HouseMate
//

import Foundation

@MainActor
final class ServiceObservation {

    private var cancellation: (() -> Void)?

    init(cancellation: @escaping () -> Void) {
        self.cancellation = cancellation
    }

    func cancel() {
        cancellation?()
        cancellation = nil
    }

    deinit {
        cancellation?()
    }
}
