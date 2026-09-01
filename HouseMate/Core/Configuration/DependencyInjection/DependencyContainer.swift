//
//  DependencyContainer.swift
//  HouseMate
//
//  Created by Marcin Turek on 26/08/2026.
//

import Foundation

@MainActor
final class DependencyContainer {

    let authService: any AuthServiceProtocol
    let userService: any UserServiceProtocol
    let householdManager: HouseholdManager
    let taskManager: TaskManager
    let shoppingManager: ShoppingManager
    let billManager: BillManager
    let householdBoardManager: HouseholdBoardManager
    let pollManager: PollManager
    let houseReminderManager: HouseReminderManager
    let notificationManager: NotificationManager
    let localNotificationService: any LocalNotificationServiceProtocol

    init(
        authService: any AuthServiceProtocol,
        userService: any UserServiceProtocol,
        householdManager: HouseholdManager,
        taskManager: TaskManager,
        shoppingManager: ShoppingManager,
        billManager: BillManager,
        householdBoardManager: HouseholdBoardManager,
        pollManager: PollManager,
        houseReminderManager: HouseReminderManager,
        notificationManager: NotificationManager,
        localNotificationService: any LocalNotificationServiceProtocol
    ) {
        self.authService = authService
        self.userService = userService
        self.householdManager = householdManager
        self.taskManager = taskManager
        self.shoppingManager = shoppingManager
        self.billManager = billManager
        self.householdBoardManager = householdBoardManager
        self.pollManager = pollManager
        self.houseReminderManager = houseReminderManager
        self.notificationManager = notificationManager
        self.localNotificationService = localNotificationService
    }

    static func make() -> DependencyContainer {
        make(
            environment: AppEnvironment.current
        )
    }

    static func make(
        environment: AppEnvironment
    ) -> DependencyContainer {
        switch environment {
        case .mock:
            let userService = MockUserService()
            let localNotificationService = MockLocalNotificationService()
            let householdManager = HouseholdManager(
                householdService: MockHouseholdService(),
                userService: userService
            )

            return DependencyContainer(
                authService: MockAuthService(),
                userService: userService,
                householdManager: householdManager,
                taskManager: TaskManager(service: MockTaskService(), notificationService: localNotificationService),
                shoppingManager: ShoppingManager(service: MockShoppingService()),
                billManager: BillManager(service: MockBillService(), notificationService: localNotificationService),
                householdBoardManager: HouseholdBoardManager(service: MockHouseholdBoardService()),
                pollManager: PollManager(service: MockPollService()),
                houseReminderManager: HouseReminderManager(
                    service: MockHouseReminderService(),
                    notificationService: localNotificationService
                ),
                notificationManager: NotificationManager(service: MockNotificationService()),
                localNotificationService: localNotificationService
            )

        case .development, .production:
            let userService = FirebaseUserService()
            let localNotificationService = LocalNotificationService()
            let householdManager = HouseholdManager(
                householdService: FirebaseHouseholdService(),
                userService: userService
            )

            return DependencyContainer(
                authService: FirebaseAuthService(),
                userService: userService,
                householdManager: householdManager,
                taskManager: TaskManager(service: FirebaseTaskService(), notificationService: localNotificationService),
                shoppingManager: ShoppingManager(service: FirebaseShoppingService()),
                billManager: BillManager(service: FirebaseBillService(), notificationService: localNotificationService),
                householdBoardManager: HouseholdBoardManager(service: FirebaseHouseholdBoardService()),
                pollManager: PollManager(service: FirebasePollService()),
                houseReminderManager: HouseReminderManager(
                    service: FirebaseHouseReminderService(),
                    notificationService: localNotificationService
                ),
                notificationManager: NotificationManager(service: FirebaseNotificationService()),
                localNotificationService: localNotificationService
            )
        }
    }
}
