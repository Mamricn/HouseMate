import SwiftUI

@MainActor
final class ScreenAnalyticsTracker {
    private let logService: any LogService

    init(logService: any LogService) {
        self.logService = logService
    }

    func trackScreen(_ event: any LoggableEvent) {
        logService.trackScreen(event)
    }

    func trackEvent(_ event: any LoggableEvent) {
        logService.trackEvent(event)
    }
}

private struct ScreenAnalyticsTrackerKey: EnvironmentKey {
    static let defaultValue: ScreenAnalyticsTracker? = nil
}

extension EnvironmentValues {
    var screenAnalyticsTracker: ScreenAnalyticsTracker? {
        get { self[ScreenAnalyticsTrackerKey.self] }
        set { self[ScreenAnalyticsTrackerKey.self] = newValue }
    }
}

struct AppearAnalyticsViewModifier: ViewModifier {
    @Environment(\.screenAnalyticsTracker) private var tracker

    let name: String

    func body(content: Content) -> some View {
        content
            .onAppear {
                tracker?.trackScreen(Event.appear(name: name))
            }
            .onDisappear {
                tracker?.trackEvent(Event.disappear(name: name))
            }
    }

    enum Event: LoggableEvent {
        case appear(name: String)
        case disappear(name: String)

        var eventName: String {
            switch self {
            case .appear(let name):
                return "\(name)_Appear"
            case .disappear(let name):
                return "\(name)_Disappear"
            }
        }

        var parameters: [String: Any]? { nil }
        var type: LogType { .analytic }
    }
}

extension View {
    func screenAppearAnalytics(name: String) -> some View {
        modifier(AppearAnalyticsViewModifier(name: name))
    }
}
