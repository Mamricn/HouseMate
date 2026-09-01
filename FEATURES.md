# HouseMate Features

## Planned

### Notifications

- First add local iOS notifications for upcoming bills, assigned tasks, and house reminders.
- Let the user choose when to be notified: on the day, 1 day before, 2 days before, or 1 week before.
- Add notification preferences so each user can enable or disable individual notification categories.
- Do not send notifications for routine household activity such as votes, purchased shopping items, completed tasks, or every board update.
- Later add Firebase Cloud Messaging with APNs and Cloud Functions.
- Use cloud notifications for reminders created or changed by another housemate, so delivery does not depend on opening HouseMate on the recipient's phone.
- Store and maintain an FCM token for every signed-in device.
- Send notifications only to relevant household members and respect each user's notification preferences.
- Support cancelling or rescheduling notifications when their bill, task, or reminder is changed, completed, paid, or deleted.

### Recurring bills and payment history

- Keep every paid bill as a permanent payment-history entry.
- Do not reset an existing bill from `paid` back to `upcoming`.
- Add `paidAt` to `BillModel` to record when the payment was made.
- Keep `paidByUserId` to show which housemate paid the bill.
- Add `seriesId` to connect occurrences of the same recurring bill.
- When a recurring bill is marked as paid, create a new bill occurrence with:
  - a new `billId`,
  - the next due date based on its recurrence,
  - status set to `upcoming`,
  - empty `paidByUserId` and `paidAt`.
- Do not create a new occurrence for non-recurring bills.
- Make creation of the next occurrence idempotent to prevent duplicates.
- Later, move recurring-bill generation to a scheduled Cloud Function so it does not depend on opening the app.

### Shared bills state

- Add `BillServiceProtocol`, `MockBillService`, and `FirebaseBillService`.
- Add one shared `BillsManager` to `DependencyContainer` and `CoreInteractor`.
- Make Home and Household observe the same bills source.
- Synchronise bill status changes with every household member through Firestore.

### All Bills presentation

- Keep paid bills visible in All Bills.
- Show status badges for `upcoming`, `overdue`, and `paid`.
- For paid bills, display the payer and payment date.
- Separate outstanding bills from payment history.
