import Foundation

@MainActor
enum AnalyticsServiceFactory {
    static func make(for environment: AppEnvironment) -> any LogService {
        let console = ConsoleLogService()

        guard environment.usesFirebase else {
            return console
        }

        let crashlytics = CrashlyticsLogService(
            environment: environment
        )

        guard let token = environment.mixpanelToken else {
            return CompositeLogService(
                services: [console, crashlytics]
            )
        }

        let mixpanel = MixpanelLogService(
            token: token,
            loggingEnabled: environment == .development,
            flushesImmediately: environment == .development
        )

        if environment == .development {
            return CompositeLogService(
                services: [console, mixpanel, crashlytics]
            )
        }

        return CompositeLogService(
            services: [mixpanel, crashlytics]
        )
    }
}
