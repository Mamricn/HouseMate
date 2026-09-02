# HouseMate 1.0 Roadmap

This file is the main checklist for preparing HouseMate 1.0. Detailed feature
notes can remain in `FEATURES.md`.

## Current foundation

- [x] Core household features: tasks, shopping, bills, reminders, polls and board
- [x] Realtime synchronisation for the main household data
- [x] Local notification MVP
- [x] Inline form validation with error haptics
- [x] Protection against duplicate local items from realtime listeners
- [x] Realtime household-member synchronisation
- [x] Atomic Firebase household membership updates

## 1. Navigation and application structure

- [x] Add a central app router and typed routes
- [ ] Split routes into household, account and notification areas
- [x] Add central destination mapping for new screens
- [ ] Reset navigation after logout, account deletion or leaving a household
- [ ] Support opening a specific screen from a notification
- [ ] Migrate existing navigation gradually without rewriting every screen at once

## 2. Household ownership and member management

- [x] Add `ownerUserId` while preserving the historical creator
- [x] Keep older household documents compatible by treating their creator as owner
- [x] Use ownership internally for permissions without displaying an Owner badge
- [x] Add a Household Settings screen
- [x] Add an Add Member button and invitation flow
- [x] Show and share the household invitation code
- [ ] Display the household member list with roles
- [x] Allow the owner to remove a member
- [x] Allow a member to leave the household
- [ ] Define what happens when a user no longer belongs to a household
- [x] Return users without a household to the create/join onboarding flow

## 3. Household ownership and deletion

- [x] Allow the owner to transfer ownership to another member
- [x] Prevent the owner from leaving before transferring ownership or deleting the household
- [x] Add a confirmation flow for ownership transfer
- [x] Allow the owner to delete the household
- [x] Delete all related tasks, shopping items, bills, reminders, polls and board posts
- [x] Clear the household reference for every member
- [ ] Perform destructive multi-document operations on a trusted backend
- [ ] Make deletion retry-safe so a partial failure does not leave ghost data

## 4. Profile photos

- [ ] Add photo selection from the photo library
- [ ] Add preview and crop support
- [ ] Resize and compress images before upload
- [ ] Upload avatars to Firebase Storage
- [ ] Store the avatar reference or URL in the user profile
- [ ] Provide an initials-based fallback avatar
- [ ] Allow users to replace and remove their own photo
- [ ] Display avatars in the member list, posts, polls and assignment pickers
- [ ] Add upload progress and error states
- [ ] Cache downloaded images to avoid unnecessary network usage
- [ ] Delete the previous image after replacement and on account deletion
- [ ] Restrict image type and maximum file size

## 5. Account management

- [x] Add an Account Settings screen
- [x] Add a Delete Account button and confirmation flow
- [x] Require recent authentication for sensitive operations
- [x] Handle account deletion when the user owns a household
- [ ] Remove or anonymise user references in retained history where appropriate
- [ ] Delete the user profile, device tokens and avatar (profile and notifications done; tokens/avatar follow with those features)
- [x] Delete the Firebase Authentication account only after data cleanup succeeds
- [ ] Add a clear recovery path if account deletion fails partway through

## 6. Advanced notifications

- [ ] Configure APNs and Firebase Cloud Messaging
- [ ] Store, refresh and remove device tokens per signed-in device
- [ ] Add server-triggered notifications for activity created by another member
- [ ] Notify users about assigned tasks
- [ ] Notify users about upcoming bills and reminders
- [ ] Decide whether new polls and important board posts should notify members
- [ ] Add per-category notification preferences
- [ ] Respect system notification permission status
- [ ] Handle notifications while the app is open
- [ ] Add deep linking to the relevant screen or item
- [ ] Cancel or reschedule notifications when source data changes
- [ ] Avoid duplicate local and remote notifications

See `FEATURES.md` for the detailed notification policy.

## 7. UX consistency and resilience

- [ ] Review every form for consistent validation behaviour
- [ ] Prevent repeated Create, Save and Delete submissions
- [ ] Add consistent loading, empty, success and error states
- [ ] Add confirmations for destructive actions
- [ ] Add retry actions for recoverable network errors
- [ ] Test offline mode, reconnects and slow connections
- [ ] Define optimistic-update rollback behaviour
- [ ] Audit realtime listeners for duplicates, leaks and unnecessary reads
- [ ] Review swipe-action presentation and other known visual rough edges
- [ ] Test keyboard handling and focus on every form
- [ ] Verify layouts on small and large iPhones
- [ ] Decide whether 1.0 supports Dark Mode or explicitly uses Light Mode
- [ ] Check Dynamic Type, VoiceOver labels, touch targets and contrast

## 8. Analytics and diagnostics

- [ ] Add Firebase Analytics
- [ ] Define a small event naming convention before adding events
- [ ] Track important flows without personal data in event names or parameters
- [ ] Track failures and cancelled flows where they provide useful product insight
- [ ] Add Firebase Crashlytics
- [ ] Verify that development activity does not pollute production analytics
- [ ] Document analytics and crash reporting in the privacy information

## 9. Backend security and data quality

- [ ] Finalise Firestore Security Rules after roles and ownership are stable
- [ ] Add Firebase Storage Rules for profile images
- [ ] Add Firebase App Check
- [ ] Validate privileged operations on the backend
- [ ] Add and document required Firestore indexes
- [ ] Review query cost and unnecessary document reads
- [ ] Separate Development and Production Firebase configuration
- [ ] Test rules using the Firebase Emulator Suite
- [ ] Plan schema migrations for future model changes

## 10. Testing and release

- [ ] Test the complete flow with at least two real accounts
- [ ] Test owner/member permissions and ownership transfer
- [ ] Test household deletion and account deletion failure scenarios
- [ ] Test notification delivery on physical devices
- [ ] Add unit tests for critical managers and ownership rules
- [ ] Add focused integration tests for Firebase flows
- [ ] Test sign-out, session restoration and switching accounts
- [ ] Prepare app icon, launch experience and App Store screenshots
- [ ] Add Privacy Manifest and complete App Store privacy declarations
- [ ] Add a privacy policy and support/contact information
- [ ] Prepare production Firebase configuration
- [ ] Run an internal TestFlight test before inviting external testers
- [ ] Fix release-blocking feedback and submit HouseMate 1.0

## Later versions

- [ ] Recurring tasks and richer task history
- [ ] Recurring bills with permanent payment history
- [ ] Expense splitting and settlement tracking
- [ ] Shared household calendar
- [ ] Widgets and App Intents
- [ ] Data export
- [ ] Localisation
- [ ] Themes and deeper appearance customisation
- [ ] Household photo

## Recommended implementation order

1. Navigation and routing
2. Roles and member management
3. Profile photos
4. Ownership transfer, leaving and household deletion
5. Account deletion
6. Advanced notifications
7. UX and offline/retry hardening
8. Analytics and Crashlytics
9. Security rules, App Check and emulator tests
10. Release testing and TestFlight
