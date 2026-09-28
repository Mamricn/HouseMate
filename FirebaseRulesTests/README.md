# Firebase Rules Tests

These tests verify `firestore.rules` against a local Firestore emulator. They do
not connect to the HouseMate Development or Production databases.

## Run the tests

From the root `HouseMate` directory run:

```bash
npm run test:rules
```

The command starts a temporary Firestore emulator, runs every `*.test.js` file
in this directory and then stops the emulator automatically.

`PERMISSION_DENIED` messages are expected in tests that verify a forbidden
operation. The final summary should report zero failed tests.

## Covered behaviour

- signed-out access is rejected;
- household members cannot perform owner-only operations;
- owners can remove household members;
- signed-in outsiders cannot read household documents;
- signed-in users can resolve only minimal invite documents;
- invite documents cannot be listed in bulk;
- only owners can disable household invites;
- disabled invites prevent new members from joining;
- users outside a household cannot access its tasks;
- task authors cannot be forged;
- task updates are limited to permitted fields;
- user profiles are private;
- notification recipients can mark notifications as read;
- protected notification fields cannot be changed by clients.
