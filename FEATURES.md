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

### House reminder details

- Make every saved reminder row open a dedicated details screen.
- Keep the row compact and move complete information to the details screen.
- Show the reminder title, note or description, next occurrence, time, recurrence,
  notification timing and creation date.
- Present recurrence in plain language, for example `Every week`, `Every month`
  or `Every year`.
- Add actions to edit, delete and mark the reminder as completed where applicable.
- Keep the next occurrence consistent after recurrence settings are edited.

### Bill details

- Make every bill row open a dedicated details screen.
- Show its title, amount, category, due date, status, recurrence, note, creator and
  creation date.
- For paid bills, show `paidAt` and the member who marked the bill as paid.
- Add actions to edit, delete and switch between paid and pending when allowed.

### Bills analytics dashboard

- Add a dedicated Bills screen rather than placing all analytics inside the Home card.
- Support week, month, six-month and year periods first; add a custom range later only
  if it is useful.
- Calculate spending from `paidAt`. For historical paid bills without this field,
  temporarily fall back to their due date.
- Show the total spent, average monthly spending, largest expense and recurring monthly
  cost estimate.
- Split spending by category and allow filtering by category and household member.
- Compare the selected period with the equivalent previous period.
- Show paid, upcoming and overdue bills separately.
- Use a simple time-series bar or line chart and a readable category breakdown.
- Keep monthly budgets, unusual-spending warnings, receipt photos, search and CSV export
  as follow-up improvements after the main dashboard works reliably.
