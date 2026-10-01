# QR Code Generator 📱⚡

A modern, offline, and feature-rich QR Code Generator and Scanner built with **Flutter 3.47+** and **Dart 3.13+**. Designed with a clean feature-oriented architecture, null safety, responsive UI, live theme customization, persistent history & favorites, camera/gallery QR scanning, and native export/share capabilities.

---

## 📸 Screenshots

| Create & Customization | Camera QR Scanner | History & Favorites | Settings & Dark Theme |
|:---:|:---:|:---:|:---:|
| *(Add Create Screen)* | *(Add Scanner Screen)* | *(Add History Screen)* | *(Add Settings Screen)* |

---

## ✨ Features

- **Actual QR Code Generation**: Instant offline QR encoding powered by `qr_flutter`.
- **7 Professional QR Content Types & Dynamic Forms**:
  - 📝 **Plain Text**: Multiline text input for notes, messages, and arbitrary strings.
  - 🌐 **Website / URL**: Link input with automatic protocol normalization (`https://`).
  - 📶 **Wi-Fi Network**: Network SSID, password, security selector (`WPA/WPA2`, `WEP`, `None`), password visibility toggle, and hidden network flag. Enforces minimum 8-character password for WPA/WPA2.
  - ✉️ **Email**: Recipient email address (with regex validation), optional subject, and message body encoded via RFC standard `mailto:` schema.
  - 📞 **Phone Number**: Direct telephone dialing encoded via standard `tel:` URI.
  - 👤 **Contact / vCard**: Universal vCard 3.0 standard payload with full name, phone, email, and organization for 1-tap address book import on any smartphone.
  - 💬 **SMS**: Recipient phone number and message body formatted as `smsto:` URI.
- **⚡ Quick Templates & Recent Quick Actions**:
  - **Quick Templates**: 1-tap starter chips (Website, Wi-Fi, Contact, Email, Phone, SMS, Text) that immediately switch to the corresponding form.
  - **Recent Quick Actions**: Prominent, responsive action bar on the Home/Create screen for rapid navigation: **Create QR**, **Scan QR**, **History**, and **Favorites**.
- **📷 Real-Time Camera & Gallery QR Scanner**:
  - 📸 **Live Camera Scanning**: High-performance QR scanning using `mobile_scanner` with flashlight toggle, front/back camera switching, and custom viewfinder reticle.
  - 🖼️ **Image QR Scanner**: Pick existing images, photos, or screenshots from the device gallery and detect QR codes with graceful error handling.
  - 🛡️ **Safe URL Confirmation Guard**: Shows an explicit confirmation dialog before opening external websites to prevent accidental malicious navigation.
  - 🎯 **Contextual Actions**:
    - Open URL in browser
    - Direct phone dialing (`tel:`)
    - Direct SMS composition (`sms:`)
    - Direct Email composition (`mailto:`)
    - Copy to clipboard
    - Share content
    - Save to local history
    - 1-tap "Scan Another Code" action
  - 🚫 **Permission & Error Handling**: Graceful fallback when camera access is denied, with friendly prompt and alternative gallery upload option.
- **🎨 Advanced Live Customization & Preview**:
  - **Dots & Eyes Color**: 10 curated foreground colors (Slate Dark, Indigo, Sky Blue, Teal, Emerald, Amber, Rose, Purple, Plum, Jet Black).
  - **Canvas Background Color**: 6 soft background canvases (Pure White, Soft Slate, Soft Indigo, Soft Mint, Warm Cream, Soft Rose).
  - **WCAG Contrast Guard**: Real-time luminance contrast ratio calculation (`contrastRatio >= 3.0:1`) with an alert banner warning users against low-contrast combinations.
  - **QR Size Slider**: Fluid logical sizing from 160px to 280px.
  - **Error Correction**: 4 selectable Reed-Solomon recovery levels (`L`: 7%, `M`: 15%, `Q`: 25%, `H`: 30%).
  - **Eye & Data Dot Shapes**: Switch between standard Square modules and modern Rounded/Circular dots and eye corner frames.
  - **Form & Style Reset**: 1-tap reset action in the AppBar that clears the active form, restores default styling (black dots, white background, size 220, level M), and resets to Plain Text mode.
- **💾 Complete QR History & Favorites System**:
  - **Local Persistence**: Automatic persistent local storage via `shared_preferences` without any backend or Firebase.
  - **100% Backwards Compatible**: Existing saved history data seamlessly deserializes without errors, gracefully populating default styling values for older records.
  - **Smart Deduplication**: Re-generating identical content updates the timestamp, preserves favorite status, and bumps the item to the top.
  - **Favorites**: 1-tap favorite toggle on both the Generator screen and History list.
  - **Real-Time Search**: Smoothly filters records by content with a dedicated "No Results Found" empty state and clear action.
  - **Safe Deletion**: Single item deletion with confirmation; bulk history clear with explicit option to preserve favorites.
  - **QR Detail Screen**: Full inspection of any historical or favorite QR code with selectable content, character count, save/share actions, and 1-tap "Open in Generator" restoration.
- **⚙️ Settings & Personalization**:
  - **Theme Mode**: Persisted switching between System Default, Light Mode, and Dark Mode.
  - **Data Management**: View total saved QR codes and clear history.
  - **Privacy Policy**: In-app policy detailing 100% offline, privacy-first processing with zero tracking or telemetry.
  - **About & Version**: Application details and versioning (1.0.0+1).
  - **Share & Rate App**: System share sheet integration and 5-star rating dialog.
  - **Walkthrough Revisit**: Replay onboarding anytime from settings.
- **🚀 Lightweight Onboarding Experience**:
  - 3-step walkthrough introducing QR Creation & Customization, Camera & Gallery Scanning, and Offline History & Favorites.
  - Skip, Next, and Get Started navigation with local persistence so it only displays once.
- **🧭 Clean Bottom Navigation Architecture**:
  - Material 3 `NavigationBar` with 4 primary destinations: **Create**, **Scan**, **History**, and **Settings**.
  - State preservation with `IndexedStack`.

---

## 🏗️ Project Architecture

```
lib/
├── main.dart                                # Application entry point, theme & onboarding routing
├── core/
│   ├── theme/
│   │   ├── app_theme.dart                   # Color palette, light/dark themes, WCAG contrast calculation
│   │   └── theme_controller.dart            # System/Light/Dark mode state management & persistence
│   └── utils/
│       ├── qr_image_exporter.dart           # RepaintBoundary capture, gallery saving, share
│       └── snackbar_helper.dart             # Modern floating feedback SnackBars
└── features/
    ├── navigation/
    │   └── presentation/
    │       └── screens/
    │           └── main_navigation_screen.dart # Top-level 4-destination NavigationBar container
    ├── onboarding/
    │   └── presentation/
    │       └── screens/
    │           └── onboarding_screen.dart   # 3-step onboarding walkthrough with persistence
    ├── qr_generator/
    │   ├── models/
    │   │   ├── qr_config.dart               # QR configuration data model (shapes, size, colors)
    │   │   └── qr_payload_type.dart         # Enum defining supported QR data types with metadata
    │   ├── utils/
    │   │   └── qr_payload_encoder.dart      # RFC standard payload encoders (vCard, Wi-Fi, mailto, tel, smsto)
    │   ├── controllers/
    │   │   └── qr_generator_controller.dart # Multi-form state, validation, styling mutators, reset
    │   └── presentation/
    │       ├── screens/
    │       │   └── qr_generator_screen.dart # Main creation screen with quick actions & templates
    │       └── widgets/
    │           ├── qr_action_buttons.dart   # Save, Share, and Copy buttons with progress
    │           ├── qr_display_card.dart     # Prominent QR preview & live customization panel
    │           ├── qr_dynamic_form.dart     # Dedicated dynamic input form fields per QR type
    │           ├── qr_empty_state.dart      # Empty state with interactive preset templates
    │           ├── qr_input_card.dart       # Form container with type selector, validation & actions
    │           ├── qr_type_selector.dart    # Polished horizontal type chip selector
    │           ├── quick_actions_bar.dart   # Responsive Create, Scan, History, Favorites quick buttons
    │           └── quick_templates_bar.dart # 1-tap template chips (Website, Wi-Fi, Contact, etc.)
    ├── qr_scanner/
    │   └── presentation/
    │       ├── screens/
    │       │   └── qr_scanner_screen.dart   # Camera viewfinder, overlay, flash/camera toggle, gallery scan
    │       └── widgets/
    │           └── scanned_result_sheet.dart # Detected content modal with safety URL confirmation & actions
    ├── qr_history/
    │   ├── models/
    │   │   └── qr_item.dart                 # Data model for persistent QR history records with styling
    │   ├── services/
    │   │   └── qr_storage_service.dart      # SharedPreferences JSON persistence layer
    │   ├── controllers/
    │   │   └── qr_history_controller.dart   # History & Favorites state management
    │   └── presentation/
    │       ├── screens/
    │       │   ├── qr_history_screen.dart   # Tabbed (All / Favorites) searchable screen
    │       │   └── qr_detail_screen.dart    # Full QR inspection, export, favorite, and delete
    │       └── widgets/
    │           ├── delete_confirmation_dialog.dart # Delete single / bulk confirmation dialogs
    │           ├── qr_history_empty_state.dart     # Dynamic empty states (history, favorites, search)
    │           └── qr_history_tile.dart            # History list item card with thumbnail & styling
    └── settings/
        └── presentation/
            └── screens/
                └── settings_screen.dart     # Settings screen (theme, storage, privacy, about, rating)
```

---

## 📦 Packages Added

| Package | Version | Purpose |
|---|---|---|
| `qr_flutter` | `^4.1.0` | Real-time QR code rendering and styling |
| `mobile_scanner` | `^7.4.2` | Real-time camera QR scanning and image analysis |
| `image_picker` | `^1.2.3` | Selecting photos from device gallery for QR detection |
| `url_launcher` | `^6.3.2` | Contextual actions for URLs, phone calls, SMS, and emails |
| `gal` | `^2.3.3` | Saving exported PNG images to device photo gallery |
| `share_plus` | `^13.3.0` | Native OS share sheet integration |
| `path_provider` | `^2.1.6` | Accessing temp and storage directories for exports |
| `shared_preferences` | `^2.5.5` | Lightweight, offline local storage for history, favorites, theme, and onboarding |

---

## ⚙️ Platform Setup

### Android (`android/app/src/main/AndroidManifest.xml`)
- Added `CAMERA` permission (`android.permission.CAMERA`).
- Added `WRITE_EXTERNAL_STORAGE` permission (scoped up to API 29).
- Added `requestLegacyExternalStorage="true"` to `<application>`.
- Set human-readable application label: `android:label="QR Code Generator"`.
- Added `<queries>` block declaring URL intent schemes (`https`, `http`, `tel`, `mailto`, `smsto`).

### iOS (`ios/Runner/Info.plist`)
- Added `NSCameraUsageDescription` key for QR camera scanning.
- Added `NSPhotoLibraryAddUsageDescription` key for gallery saving.
- Added `NSPhotoLibraryUsageDescription` key for photo selection and QR code detection.

---

## 🚀 How to Run the Project

1. **Install Flutter & Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run in Debug Mode**:
   ```bash
   flutter run
   ```

3. **Run in Release Mode**:
   ```bash
   flutter run --release
   ```

---

## 🔨 How to Build the Project

### Android
Build release APK:
```bash
flutter build apk --release
```

Build Google Play release AppBundle:
```bash
flutter build appbundle --release
```

*Note: For official Google Play distribution, configure your signing key in `android/key.properties` as described in the official Flutter documentation.*

---

## 🧪 Testing & Verification

Run static code analysis:
```bash
flutter analyze
# Result: No issues found!
```

Run comprehensive unit & widget test suite (38 tests):
```bash
flutter test
# Result: All tests passed! (38/38 passed)
```

Build application bundle:
```bash
flutter build bundle
# Result: Built bundle successfully (Exit code 0)
```

---

## 🔮 Future Improvements

- **Custom Logo Embedding**: Allow users to place their brand logo in the center of the QR code using high error-correction levels.
- **Batch Export**: Export multiple selected history items as a combined PDF or ZIP archive.
- **Barcode Formats**: Support 1D barcodes (Code128, EAN-13, UPC) in addition to 2D QR codes.
- **NFC Tag Writing**: Allow writing formatted Wi-Fi or contact credentials directly to NFC tags.
