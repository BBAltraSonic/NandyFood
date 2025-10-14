# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

Project overview
- App: Flutter (Dart) multi-platform app with Riverpod for state management, Supabase as backend, Paystack for payments, flutter_map for maps, and extensive runtime logging utilities.
- Backend: Supabase Postgres (migrations in supabase/migrations) and Edge Functions (TypeScript) for payment flows: initialize-paystack-payment and verify-paystack-payment.
- Configuration: Environment via .env (loaded with flutter_dotenv; .env is included as an asset in pubspec.yaml). Do not commit secrets. Use placeholders like {{PAYSTACK_SECRET_KEY}} and set actual values via secure channels or Supabase secrets.

Key development commands
- Install and prepare
  ```bash path=null start=null
  flutter pub get
  ```
- Run the app (choose a device)
  ```bash path=null start=null
  # Auto-detect device
  flutter run

  # Explicit targets
  flutter run -d chrome
  flutter run -d windows
  flutter run -d emulator-5554
  ```
- Run with rich runtime logging (Test Mode)
  ```bash path=null start=null
  # Test-mode entrypoint with on-screen log viewer and analytics
  flutter run lib/main_test.dart -d chrome
  ```
- Optional helper script (Windows, interactive)
  ```powershell path=null start=null
  .\run_with_logs.ps1
  ```
- Lint and format
  ```bash path=null start=null
  # Static analysis (uses analysis_options.yaml)
  flutter analyze

  # Format and fail on diff (useful before commits/CI)
  dart format --output=none --set-exit-if-changed .
  ```
- Code generation (JSON serializable, etc.)
  ```bash path=null start=null
  dart run build_runner build --delete-conflicting-outputs
  ```
- Tests
  ```bash path=null start=null
  # Run all tests
  flutter test -r expanded

  # Run a single test file
  flutter test test/unit/services/payment_service_test.dart -r expanded

  # Filter by name (group or test)
  flutter test -n "PaymentService"

  # Run the consolidated suite
  flutter test test/all_tests.dart -r expanded
  ```
- Builds
  ```bash path=null start=null
  # Android
  flutter build apk --release
  # or
  flutter build appbundle --release

  # Web
  flutter build web --release

  # Windows (on Windows only)
  flutter build windows --release

  # iOS/macOS require Apple platforms and Xcode
  # flutter build ios --release      # on macOS
  # flutter build macos --release    # on macOS
  ```

Backend (Supabase + Paystack)
- Prereqs: Install Supabase CLI (see INSTALL_SUPABASE_CLI.md for Scoop and other options). You can also deploy via the Supabase Dashboard without the CLI.
- Automated setup (Windows):
  ```powershell path=null start=null
  # Links project, sets secrets, deploys functions, applies migrations
  .\deploy_setup.ps1
  ```
- Manual CLI flow:
  ```bash path=null start=null
  # Authenticate and link
  supabase login
  supabase link --project-ref <YOUR_SUPABASE_PROJECT_ID>

  # Set required secret for Paystack Edge Functions
  supabase secrets set PAYSTACK_SECRET_KEY={{PAYSTACK_SECRET_KEY}}

  # Deploy Edge Functions
  supabase functions deploy initialize-paystack-payment
  supabase functions deploy verify-paystack-payment

  # Apply database migrations
  supabase db push

  # Verify
  supabase functions list
  supabase secrets list
  ```
- Dashboard flow (no CLI):
  - Create two Edge Functions named initialize-paystack-payment and verify-paystack-payment, paste code from supabase/functions/*/index.ts, deploy, and set PAYSTACK_SECRET_KEY in Settings → Edge Functions → Secrets. Run SQL from relevant migration files via the SQL Editor if needed.

Environment and secrets
- Local env file:
  - Copy .env.example to .env and fill placeholders (e.g., SUPABASE_URL, SUPABASE_ANON_KEY, PAYSTACK_PUBLIC_KEY, PAYSTACK_SECRET_KEY, etc.).
  - .env is loaded by flutter_dotenv (asset is declared in pubspec.yaml). Restart the app after changes; hot reload won’t re-read .env.
- Server-side secrets (Supabase):
  - Set PAYSTACK_SECRET_KEY in Supabase secrets for Edge Functions as shown above. Never embed secrets directly in client code.
- Firebase/FCM: optional and not enabled by default in this repo (no Firebase packages are declared in pubspec.yaml).

High-level architecture and structure
- Layered organization (big picture):
  - core/
    - config and constants for app-wide configuration.
    - providers for app-level state (auth, theme, base), implemented with Riverpod.
    - services encapsulating domain operations and side effects: auth, database (Supabase), payments (Paystack flows via Supabase functions), storage, notifications, location, delivery tracking.
  - features/
    - Vertical slices by domain (authentication, home, restaurant, order, profile). Each slice groups presentation concerns (screens, widgets) and feature-level providers.
  - shared/
    - models with json_serializable and generated *.g.dart files used across features.
    - theme and UI widgets reused throughout the app.
  - test/
    - unit, widget, and integration tests organized by type, with a consolidated test runner at test/all_tests.dart.
  - supabase/
    - migrations define tables, RLS, buckets, etc.
    - functions (TypeScript Edge Functions) handle payment flows and shared CORS helper.
- State management: Riverpod (flutter_riverpod) is the primary mechanism. Providers live under core/providers and within feature slices.
- Payments: The app uses flutter_paystack_plus for client UI and invokes Supabase Edge Functions for server-side Paystack initialization/verification.
- Maps: flutter_map with OpenStreetMap tiles (no Google Maps key required by default), see lib/features/home/... map widgets and core/services/location_service.dart.
- Runtime logging and Test Mode: lib/test_runner.dart provides structured logging (function entry/exit, levels, export/stats). Running lib/main_test.dart activates an on-screen log viewer and analytics panel to accelerate manual testing and debugging.

Notes from existing docs
- README.md: Provides a clear overview of features, layered architecture, and getting started. Use it alongside this file for onboarding details.
- QUICK_START.md and QUICK_START_TESTING.md: Contain up-to-date Supabase/Paystack setup, device/run commands, and test-payment instructions. Prefer these for environment-specific steps.
- CLAUDE.md: Parts are generic (e.g., unrelated pytest/ruff commands). Treat the technology notes mentioning Riverpod, Supabase, flutter_map as relevant; disregard the unrelated command examples. If guidance in CLAUDE.md conflicts with this file, prefer WARP.md.

Common troubleshooting
- Supabase CLI not found: Follow INSTALL_SUPABASE_CLI.md (Scoop recommended on Windows) or use the Supabase Dashboard method.
- .env changes not taking effect: Fully restart the Flutter app.
- Payment issues: Ensure Edge Functions are deployed and PAYSTACK_SECRET_KEY is set; inspect logs via supabase functions logs <function>.

Suggested quick workflows
- Fresh start
  ```bash path=null start=null
  flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test -r expanded
  ```
- Focused test iteration
  ```bash path=null start=null
  dart run build_runner build --delete-conflicting-outputs
  flutter test test/unit/services/payment_service_test.dart -r expanded
  ```
- Manual payment flow verification (after backend deploy)
  ```bash path=null start=null
  flutter run -d chrome
  # Checkout in-app; use Paystack test cards from their docs
  ```
