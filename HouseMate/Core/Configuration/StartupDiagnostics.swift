//
//  StartupDiagnostics.swift
//  HouseMate
//

import Foundation
import OSLog

enum StartupDiagnostics {

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "HouseMate",
        category: "Startup"
    )

    private static let processStart = ProcessInfo.processInfo.systemUptime

    static func mark(_ event: String) {
        let start = processStart
        let elapsed = ProcessInfo.processInfo.systemUptime - start
        let message = String(
            format: "[Launch +%.3fs] %@",
            elapsed,
            event
        )
        logger.notice("\(message, privacy: .public)")
    }

    static func begin(_ operation: String) -> TimeInterval {
        mark("BEGIN \(operation)")
        return ProcessInfo.processInfo.systemUptime
    }

    static func end(_ operation: String, startedAt: TimeInterval) {
        let duration = ProcessInfo.processInfo.systemUptime - startedAt
        mark(String(format: "END %@ (%.3fs)", operation, duration))
    }
}
