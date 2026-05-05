# Velocity POS

A Flutter point-of-sale application built for offline restaurant, cafe, and retail workflows. The app runs locally, stores data in SQLite, and is designed around fast order entry, menu management, inventory tracking, and receipt printing without requiring a cloud backend.

## Overview

Velocity POS is an offline-only POS system made with Flutter. It includes a cashier-facing sales screen and an admin control panel for managing catalog data, deals, inventory, orders, reporting, and receipt settings.

The project is public as a reference implementation and portfolio project. It can be adapted for small businesses that need a local POS experience on Android/Sunmi devices or desktop development environments.

## Keywords

Sunmi POS, Sunmi point of sale, Sunmi printer app, Sunmi Android POS, offline POS app, Flutter POS, restaurant POS, cafe POS, retail POS, local SQLite POS, kitchen receipt printer, thermal receipt printing, Android point of sale, POS inventory management.

## Features

- Offline SQLite database with seeded demo data
- PIN-based login for admin and cashier roles
- Touch-friendly POS screen with category filtering, deals, cart, and checkout
- Product, category, and deal bundle management
- Product variants for sizes, flavors, or other options
- Ingredient and recipe management for raw stock tracking
- Automatic stock deduction when paid orders are created
- Order history with paid and pending order support
- Admin dashboard with sales and statistics screens
- Store settings, tax/custom charges, and receipt footer configuration
- Customer and kitchen receipt printing
- Sunmi internal printer support on Android
- Network printer discovery and ESC/POS-style printing support
- Windows/Linux SQLite FFI support for local development

## Tech Stack

- Flutter
- Dart
- Provider for state management
- SQLite via `sqflite`
- `sqflite_common_ffi` for desktop development
- `sunmi_printer_plus` and a native method channel for Sunmi printing
- `intl` for date and currency formatting support
- `image_picker` for catalog image selection

## Project Structure

```text
lib/
  core/
    db/                 Local SQLite database helper and seed data
    services/           Printer services
    theme/              App theme
  features/
    admin/              Admin dashboard and management screens
    auth/               PIN login and role handling
    deals/              Deal provider
    pos/                Main POS screen, cart, product grid, checkout
    products/           Product, category, and ingredient providers
  models/               App data models
  utils/                Shared utility helpers
```

## Getting Started

### Prerequisites

- Flutter SDK 3.8.1 or newer
- Dart SDK included with Flutter
- Android Studio or VS Code with Flutter tooling
- Android device/emulator, Sunmi device, or Windows desktop target

### Install Dependencies

```bash
flutter pub get
```

### Run the App

For Android:

```bash
flutter run
```

For Windows desktop:

```bash
flutter run -d windows
```

For web testing:

```bash
flutter run -d chrome
```

Note: printing and local database behavior are primarily intended for Android/Sunmi and desktop targets. Web support may be useful for UI checks, but it is not the primary deployment target.

## Default Login PINs

The local database is seeded with demo users on first launch:

| Role | PIN |
| --- | --- |
| Admin | `1234` |
| Cashier | `0000` |

Change these PINs before using the app in a real environment.

## Offline Data

All operational data is stored locally in SQLite. The app does not require an internet connection or a remote server for daily POS use.

Local data includes:

- Users and PINs
- Categories
- Products and variants
- Deals
- Orders and order items
- Ingredients and recipes
- Store and receipt settings

## Printing

The app includes receipt printing support for:

- Internal Sunmi printers on Android devices
- Network printers using port `9100`
- Separate customer and kitchen printer settings
- Test receipt printing from system settings

Printer behavior depends on device support, network availability, and platform permissions.

## Build

Create an Android release build:

```bash
flutter build apk --release
```

Create a Windows release build:

```bash
flutter build windows --release
```

## Testing and Analysis

Run Flutter tests:

```bash
flutter test
```

Run static analysis:

```bash
flutter analyze
```

## Notes

- This project is offline only and does not include cloud sync, online payments, or multi-branch synchronization.
- The seeded demo data is intended to make the first launch usable immediately.
- Before production use, review security, backups, printing behavior, tax rules, and local business requirements.

## License

No license has been specified yet. Add a license file before allowing reuse, redistribution, or commercial use by others.
