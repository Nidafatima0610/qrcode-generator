# QR Code Generator 📱⚡

A modern, offline, and feature-rich QR Code Generator built with **Flutter 3.47+** and **Dart 3.13+**. Designed with a clean feature-oriented architecture, null safety, responsive UI, live theme customization, and native export/share capabilities.

---

## ✨ Features

- **Actual QR Code Generation**: Instant offline QR encoding powered by `qr_flutter`.
- **Multiple Payload Formats**:
  - 📝 **Plain Text**: Formatted notes and messages.
  - 🌐 **Web URLs**: Automatic protocol detection (`https://`).
  - ✉️ **Email**: Direct `mailto:` format.
  - 📞 **Phone Numbers**: Direct tel dialing format.
  - 📶 **Wi-Fi Credentials**: Standard `WIFI:S:SSID;T:WPA;P:password;;` format.
  - 💬 **SMS**: SMS template payload.
- **Modern Publishable UI**:
  - Material 3 theme with cohesive Indigo/Sky accents.
  - Light & Dark mode support.
  - Smooth micro-animations and `AnimatedSwitcher` transitions.
  - Welcoming empty state with quick sample presets.
  - Responsive layout constrained for mobile screens and larger tablet/desktop windows.
- **Real-Time Customization**:
  - 7 curated color palette options for QR code dots and eye frames.
  - 4 selectable error correction levels (`L`: 7%, `M`: 15%, `Q`: 25%, `H`: 30%).
- **Export & Share**:
  - 💾 **Save to Gallery / Storage**: High-resolution 3.5x pixel-ratio PNG export via `gal` with fallback to device documents/downloads.
  - 📤 **Native Share**: Native system share sheet integration using `share_plus`.
  - 📋 **Copy to Clipboard**: Quick copy button for encoded content.
- **Robust User Experience**:
  - Inline validation feedback for empty or invalid input.
  - Input clear button when content exists.
  - Character counter.
  - Expandable content view for long text strings.
  - Reset action to clear all states back to initial.

---

## 🏗️ Project Architecture

```
lib/
├── main.dart                                # Application entry point & theme setup
├── core/
│   ├── theme/
│   │   └── app_theme.dart                   # Color palette, light/dark themes, UI tokens
│   └── utils/
│       ├── qr_image_exporter.dart           # RepaintBoundary capture, gallery saving, share
│       └── snackbar_helper.dart             # Modern floating feedback SnackBars
└── features/
    └── qr_generator/
        ├── models/
        │   ├── qr_config.dart               # QR configuration data model
        │   └── qr_payload_type.dart         # Enum defining supported QR data types
        ├── controllers/
        │   └── qr_generator_controller.dart # ChangeNotifier separating business logic & state
        └── presentation/
            ├── screens/
            │   └── qr_generator_screen.dart # Main screen layout & coordinator
            └── widgets/
                ├── qr_action_buttons.dart   # Save, Share, and Copy buttons with progress
                ├── qr_display_card.dart     # Prominent QR preview & live customization
                ├── qr_empty_state.dart      # Empty state with interactive preset templates
                └── qr_input_card.dart       # Input card with type pills, validation & generate button
```

---

## 📦 Packages Added

| Package | Version | Purpose |
|---|---|---|
| `qr_flutter` | `^4.1.0` | Real-time QR code rendering and styling |
| `gal` | `^2.3.3` | Saving exported PNG images to device photo gallery |
| `share_plus` | `^13.3.0` | Native OS share sheet integration |
| `path_provider` | `^2.1.6` | Accessing temp and storage directories for exports |

---

## ⚙️ Platform Setup

### Android (`android/app/src/main/AndroidManifest.xml`)
- Added `WRITE_EXTERNAL_STORAGE` permission (scoped up to API 29).
- Added `requestLegacyExternalStorage="true"` to `<application>`.

### iOS (`ios/Runner/Info.plist`)
- Added `NSPhotoLibraryAddUsageDescription` key.
- Added `NSPhotoLibraryUsageDescription` key.

---

## 🧪 Testing & Verification

Run static code analysis:
```bash
flutter analyze
```

Run unit & widget test suite:
```bash
flutter test
```

Build application bundle:
```bash
flutter build bundle
```
