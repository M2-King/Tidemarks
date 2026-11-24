# Tidemark · 汐日

A countdown and count-up app for iPad and iPhone with Gregorian and Chinese lunar dates, reminders, and Home Screen and Lock Screen widgets. Black-and-white design, SwiftUI and WidgetKit.

## Get the IPA
Every push to `main` builds an unsigned `Tidemark.ipa` with GitHub Actions. Open **Actions → Build IPA → latest run → Artifacts → Tidemark-ipa**.

## Signing
The IPA is unsigned. Sign it with your own tool.

- The app and its widget share data through the App Group `group.com.tidemark.shared`. Your signing profile must allow an App Group, otherwise widgets can't see your days.
- Wildcard (`*`) provisioning profiles don't support App Groups.
- Bundle IDs: `com.tidemark.app` and `com.tidemark.app.widget`. Your signing tool may rename them; keep the widget ID as the app ID plus `.widget`.

## Requirements
iPadOS / iOS 17 or later.
