# Release readiness

## Current state

The current application stores accounts, restaurants, tables, reservations,
orders, reviews, journal entries, and checklists in `SharedPreferences`. This is
useful for a local demo, but it does not synchronize a guest's booking to a
restaurant employee's device.

Demo data is enabled in debug builds. Release builds do not seed demo accounts
unless `SERVICE_BOOK_DEMO=true` is explicitly supplied at build time.

## Cloud setup still required

The selected backend is Supabase. A project must be created and configured
before the app can use shared accounts and data. Phone verification requires
enabling the phone provider and configuring an SMS provider in Supabase Auth.
The public app key may be passed at build time; never include a service-role key
in the Flutter app.

Push notifications also need a Firebase project, Android/iOS app registrations,
and APNs credentials for iOS. Until those are configured, reservation status
remains visible only inside the app.

## Before publishing

- Apply and review the Supabase database migration and row-level security rules.
- Test guest registration, restaurant registration, booking conflicts, staff
  permissions, cancellations, and account deletion on separate devices.
- Publish a privacy policy with the operator's legal name and contact details.
- Configure release signing and unique store listing metadata.
- Test photo selection and notifications on physical Android and iOS devices.
