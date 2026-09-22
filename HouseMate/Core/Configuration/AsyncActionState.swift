//
//  AsyncActionState.swift
//  HouseMate
//

import Foundation

@Observable
@MainActor
final class AsyncActionState {

    enum ActionError: LocalizedError {
        case operationInProgress

        var errorDescription: String? {
            "Please wait for the current operation to finish."
        }
    }

    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var error: Error?

    func perform(_ operation: @MainActor () async throws -> Void) async -> Bool {
        do {
            try await run(operation)
            return true
        } catch {
            return false
        }
    }

    func run(_ operation: @MainActor () async throws -> Void) async throws {
        guard !isLoading else {
            let error = ActionError.operationInProgress
            self.error = error
            errorMessage = error.localizedDescription
            throw error
        }

        isLoading = true
        errorMessage = nil
        error = nil
        defer { isLoading = false }

        do {
            try await operation()
        } catch {
            self.error = error
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func capture(_ operation: @MainActor () async throws -> Void) async {
        _ = await perform(operation)
    }

    func clearError() {
        error = nil
        errorMessage = nil
    }
}
