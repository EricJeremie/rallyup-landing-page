# RallyUp brand asset package

This package recreates the approved RallyUp identity from the supplied brand board as individual, clean vector assets. The board itself is not used as an exported asset. The wordmark and tagline use outlined Inter letterforms (Black Italic and Bold respectively), so no font file is embedded in the deliverables.

## Brand colors

| Name | Hex | Role |
| --- | --- | --- |
| Primary dark green | `#0F2B1F` | Dark backgrounds, trajectory and app-icon base |
| Tennis green | `#A7E632` | “Up”, tennis ball, and accent icon backgrounds |
| Off white | `#F8F8F5` | Light icon background and tennis-ball seam |
| Primary text | `#1F1F1F` | Light-background wordmark |
| Secondary gray | `#8A8A8A` | Brand palette reference for supporting UI |

## Web-ready branding masters

Every logo has an SVG master and a transparent high-resolution PNG export unless noted otherwise.

| Asset | Files | Intended use | Format |
| --- | --- | --- | --- |
| Primary logo with tagline | `public/assets/branding/rallyup-logo-primary.svg`, `.png` (2560 × 1296) | Brand lockups and marketing | SVG, PNG |
| Default logo, no tagline | `public/assets/branding/rallyup-logo.svg`, `.png` (2560 × 1104) | Default app wordmark | SVG, PNG |
| Horizontal logo | `public/assets/branding/rallyup-logo-horizontal.svg`, `.png` (2560 × 581) | Navigation, headers, authentication, marketing | SVG, PNG |
| Standalone R mark | `public/assets/branding/rallyup-mark.svg`, `.png` (1200 × 900) | Compact brand placements | SVG, PNG |
| Tennis-ball mark | `public/assets/branding/rallyup-ball.svg`, `.png` (512 × 512) | Loading, badges, placeholders, accents | SVG, PNG |
| Monochrome dark logo | `public/assets/branding/rallyup-logo-dark.svg`, `.png` (2560 × 1104) | Light backgrounds | SVG, PNG |
| Monochrome light logo | `public/assets/branding/rallyup-logo-light.svg`, `.png` (2560 × 1104) | Dark backgrounds | SVG, PNG |
| Dark-background wordmark | `public/assets/branding/rallyup-logo-dark-background.svg`, `.png` (2560 × 1104) | Deep-green surfaces; white “Rally”, green “Up” | SVG, PNG |
| Splash screen logo | `public/assets/splash/rallyup-splash-logo.svg`, `.png` (2048 × 2048) | Center on the launch screen; transparent canvas | SVG, PNG |
| Favicon / small icon | `public/assets/favicon/rallyup-favicon.svg`, `rallyup-favicon-{16,32,48,64}.png`; same SVG at `public/favicon.svg` | Browser tab and shortcut icon | SVG, PNG |

The PNG logo exports use transparent backgrounds. App-icon PNGs are full-bleed squares without baked-in corner rounding, so iOS and Android can apply their native masks.

## App icons

High-resolution source/export pairs are in `public/assets/app-icons/`:

- `rallyup-app-icon.svg` / `.png` — dark-green background, white R and trajectory, tennis-green ball.
- `rallyup-app-icon-green.svg` / `.png` — tennis-green background with the dark R and tennis motif.
- `rallyup-app-icon-light.svg` / `.png` — off-white background, dark R and tennis-green ball.
- `rallyup-app-icon-foreground.svg` / `.png` — transparent vector foreground and 432 × 432 export for adaptive Android icons.

Each square app icon PNG is 1024 × 1024 and opaque (no alpha channel).

## iOS

`native/ios/Assets.xcassets/` contains three Xcode app-icon sets: `AppIcon.appiconset`, `AppIcon-Green.appiconset`, and `AppIcon-Light.appiconset`. Each `Contents.json` includes iPhone, iPad, and 1024 × 1024 App Store slots. The image files follow `RallyUp-{size}-{scale}.png`; identical pixel sizes are shared across idioms where possible. All app-icon PNGs are opaque.

Each app-icon set contains these exact PNG names: `RallyUp-20-20-1x.png`, `RallyUp-20-20-2x.png`, `RallyUp-20-20-3x.png`, `RallyUp-29-29-1x.png`, `RallyUp-29-29-2x.png`, `RallyUp-29-29-3x.png`, `RallyUp-40-40-1x.png`, `RallyUp-40-40-2x.png`, `RallyUp-40-40-3x.png`, `RallyUp-60-60-2x.png`, `RallyUp-60-60-3x.png`, `RallyUp-76-76-1x.png`, `RallyUp-76-76-2x.png`, `RallyUp-83.5-83.5-2x.png`, and `RallyUp-1024-1024-1x.png`. The catalog root also has `native/ios/Assets.xcassets/Contents.json`.

`native/ios/AlternateAppIcons-Info.plist.fragment` shows the keys to merge into the app target if the alternate icons should be user-selectable at runtime.

## Android

Merge `native/android/res/` into the Android app's `res/` directory. Density-specific `ic_launcher.png` and `ic_launcher_round.png` files cover mdpi through xxxhdpi. API 26+ uses the adaptive icon XML under `mipmap-anydpi-v26/`, with the transparent, safe-zone foreground in `drawable-nodpi/rallyup_launcher_foreground.png` and the primary dark-green background in `values/rallyup_icon_background.xml`. `native/android/play-store-icon-512.png` is the store listing master.

Exact Android files: `res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png` and `ic_launcher_round.png` in each density folder; `res/mipmap-anydpi-v26/ic_launcher.xml`; `res/mipmap-anydpi-v26/ic_launcher_round.xml`; `res/drawable-nodpi/rallyup_launcher_foreground.png`; `res/values/rallyup_icon_background.xml`; and `play-store-icon-512.png`.

## Regeneration

Run `node scripts/generate-brand-assets.mjs` from `web/` to rebuild PNG exports and native icon sets from the source vector definitions in the generator. The outlined glyph data is retained in `assets/source/rallyup-inter-paths.json`; `scripts/font-to-svg-path.swift` documents the CoreText conversion used if the wordmark paths need to be regenerated from the official [Inter releases](https://github.com/rsms/inter/releases). The font binary itself is not part of this package.
