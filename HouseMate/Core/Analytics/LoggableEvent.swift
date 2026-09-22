import Foundation

protocol LoggableEvent {
    var eventName: String { get }
    var parameters: [String: Any]? { get }
    var type: LogType { get }
}

struct AnyLoggableEvent: LoggableEvent {
    let eventName: String
    let parameters: [String: Any]?
    let type: LogType

    init(
        eventName: String,
        parameters: [String: Any]? = nil,
        type: LogType = .analytic
    ) {
        self.eventName = eventName
        self.parameters = parameters
        self.type = type
    }
}

enum LogType {
    case info
    case analytic
    case warning
    case severe

    var emoji: String {
        switch self {
        case .info: "ℹ️"
        case .analytic: "📈"
        case .warning: "⚠️"
        case .severe: "🚨"
        }
    }
}

extension Error {
    var eventParameters: [String: Any] {
        let nsError = self as NSError

        return [
            "error_type": String(describing: type(of: self)),
            "error_domain": nsError.domain,
            "error_code": nsError.code,
            "error_description": localizedDescription
        ]
    }
}
