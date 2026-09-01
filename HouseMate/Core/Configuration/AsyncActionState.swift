//
//  AsyncActionState.swift
//  HouseMate
//

import Foundation

@Observable
@MainActor
final class AsyncActionState {

    private(set) var isLoading = false
    private(set) var errorMessage: String?

    func perform(_ operation: @MainActor () async throws -> Void) async -> Bool {
        guard !isLoading else {
            errorMessage = "Please wait for the current operation to finish."
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await operation()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func capture(_ operation: @MainActor () async throws -> Void) async {
        _ = await perform(operation)
    }

    func clearError() {
        errorMessage = nil
    }
}
