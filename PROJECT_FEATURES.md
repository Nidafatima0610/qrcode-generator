# Project Features — QR Code Generator 📱⚡

This document provides a detailed breakdown of all implemented and verified features for the **QR Code Generator** Flutter internship project.

---

## 1. QR Code Creation & Multi-Type Formats
- **Standard Plain Text**: Multiline text input for general notes, passwords, arbitrary text, and messages.
- **Website / URL**: Link input with automatic protocol detection and normalization (automatically prepends `https://` if missing).
- **Wi-Fi Network Credentials**: Form fields for SSID, password, and security type (`WPA/WPA2`, `WEP`, `None`). Features a password visibility toggle and hidden network flag. Enforces a minimum 8-character password for WPA-secured networks. Encoded using the standard `WIFI:S:...;T:...;P:...;H:...;;` format with proper character escaping.
- **Email**: Fields for recipient email address, optional subject line, and message body. Enforces RFC-compliant email regex validation. Encoded using standard `mailto:` format with URL-encoded query parameters.
- **Phone Number**: Direct dialing payload formatted as `tel:` with validation ensuring at least 3 digits.
- **SMS**: Fields for recipient phone number and SMS body. Formatted as `smsto:<phone>:<message>`.
- **Contact / vCard**: Universal vCard 3.0 standard payload with full name, phone number, email address, and organization/company for 1-tap address book import on iOS and Android.

---

## 2. Dynamic Input Forms & Validation
- **Dynamic Form Swapping**: Switching the QR type dynamically renders the exact required input fields with appropriate icons, keyboard types (`TextInputType.emailAddress`, `TextInputType.phone`, `TextInputType.url`), and input actions.
- **Input Validation**: Dedicated validation rules for every payload type before generation. Displays clear inline error banners with descriptive guidance.
- **Clear Form**: 1-tap "Clear Form" action to reset active inputs.

---

## 3. Advanced Live Customization & Preview
- **Foreground Color (Dots & Eyes)**: 10 curated palette colors (Slate Dark, Indigo, Sky Blue, Teal, Emerald, Amber, Rose, Purple, Plum, Jet Black).
- **Background Color (Canvas)**: 6 soft background options (Pure White, Soft Slate, Soft Indigo, Soft Mint, Warm Cream, Soft Rose).
- **WCAG Contrast Guard**: Computes real-time relative luminance contrast ratio (`contrastRatio >= 3.0:1`). Displays an alert warning if a low-contrast color combination could impair scanner readability.
- **Size Slider**: Dynamic logical size adjustment between 160px and 280px with live canvas resizing.
- **Error Correction Level**: Selectable Reed-Solomon recovery levels (`L`: 7%, `M`: 15%, `Q`: 25%, `H`: 30%).
- **Module & Eye Shapes**: Toggle between standard Square modules and modern Rounded/Circular dots and eye corner frames.
- **Form & Style Reset**: 1-tap reset action in the AppBar that clears the active form, restores default styling (black dots, white background, size 220, level M, square shapes), and resets to Plain Text mode.

---

## 4. Real-Time Camera QR Scanner
- **Live Camera Scanning**: High-performance QR scanning powered by `mobile_scanner`.
- **Custom Viewfinder**: Translucent dark overlay with a rounded cutout and glowing corner reticle brackets.
- **Camera Controls**: 1-tap flashlight/torch toggle and front/back camera flipping.
- **Permission Handling**: Friendly fallback state when camera permission is denied, with a retry button and alternative gallery upload button.
- **Scan Again Action**: Smoothly resumes camera stream without screen reloads.

---

## 5. Image QR Scanner (Gallery Detection)
- **Photo Gallery Selection**: Pick photos, images, or screenshots from the device photo gallery via `image_picker`.
- **Image Barcode Analysis**: Decodes QR codes from static images using `MobileScannerController.analyzeImage()`.
- **Graceful Error Handling**: Displays clear feedback when the selected image does not contain a detectable QR code.

---

## 6. Smart Content Detection & Safe Actions
- **Context-Aware Bottom Sheet**: Automatically identifies detected content type (URL, Phone, Email, Wi-Fi, SMS, Text).
- **Safe URL Confirmation Guard**: Shows an explicit confirmation dialog before launching external URLs to prevent accidental or malicious redirection.
- **Contextual Actions**:
  - Open URL in default browser (`url_launcher`)
  - Direct telephone dialing (`tel:`)
  - Direct SMS composition (`sms:`)
  - Direct email composition (`mailto:`)
  - Copy to clipboard with instant feedback
  - Native system sharing (`share_plus`)
  - 1-tap save scanned code to local history

---

## 7. Quick Templates & Recent Quick Actions
- **Quick Templates**: 1-tap starter chips (Website, Wi-Fi, Contact, Email, Phone, SMS, Text) that immediately switch to the corresponding form.
- **Recent Quick Actions**: Prominent, responsive action bar on the Home/Create screen for rapid navigation: **Create QR**, **Scan QR**, **History**, and **Favorites**.

---

## 8. Offline History & Favorites System
- **100% Offline Local Storage**: Persistent storage using `shared_preferences` without Firebase or external dependencies.
- **Full Styling Persistence**: Stores custom foreground color, background color, QR size, eye shape, data module shape, and error correction level with every history record.
- **Backwards Compatibility**: Gracefully deserializes legacy records without styling fields using default values without data loss.
- **Smart Deduplication**: Re-generating identical content updates the timestamp, preserves favorite status, and bumps the item to the top of history.
- **Favorites**: 1-tap star/unstar toggle on both the main creation screen, list tiles, and detail screen.
- **Real-Time Instant Search**: Live content filter with dedicated empty state ("No Results Found") and clear query action.
- **Safe Deletion**:
  - Single item deletion with confirmation.
  - Bulk history clear with explicit option to preserve favorited records.

---

## 9. QR Detail Screen
- **Full QR Inspection**: High-definition display of the selected QR code rendered with its saved custom colors and shapes.
- **Character Count & Metadata**: Formatted creation date and character counter.
- **Open in Generator**: 1-tap button to load content and styling back into the creation form for immediate re-editing.
- **High-Resolution PNG Export**: Saves 3.5x pixel-ratio PNG to photo gallery via `gal` with local documents folder fallback.
- **Native Share**: Shares QR image file and text payload using the native OS share sheet via `share_plus`.

---

## 10. Application Settings & Personalization
- **Theme Mode**: Persisted switching between System Default, Light Mode, and Dark Mode.
- **History Statistics**: Displays total saved codes and favorites count.
- **Bulk Data Deletion**: Clear history directly from settings with confirmation.
- **Privacy Policy Modal**: Details 100% offline, privacy-first processing with zero data collection or telemetry.
- **About App Modal**: Application information and version (`1.0.0+1`).
- **Share & Rate App**: System share sheet integration and 5-star rating dialog.
- **Walkthrough Replay**: Allows users to re-launch the onboarding walkthrough anytime.

---

## 11. Lightweight First-Launch Onboarding
- **3 Explanatory Steps**:
  1. *Create & Customize QR Codes*
  2. *Scan from Camera & Gallery*
  3. *Offline History & Favorites*
- **Navigation Controls**: Skip, Next, and Get Started buttons with smooth page indicator dots.
- **Local Persistence**: Remembers completion flag in `SharedPreferences` so it only displays on initial launch.

---

## 12. Bottom Navigation Architecture
- **Material 3 NavigationBar**: 4 primary destinations: **Create**, **Scan**, **History**, and **Settings**.
- **State Preservation**: Uses `IndexedStack` to preserve state, input form drafts, and search queries when switching between tabs.
