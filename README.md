# Unit Converter

A fast, offline-first unit converter for Flutter with a **Farsi (Persian) UI**, a **Material 3 Expressive** look, and live currency rates.

<p align="center">
    <img alt="platform" src="https://img.shields.io/badge/platform-Android-blue">
    <img alt="flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white">
    <img alt="license" src="https://img.shields.io/badge/license-MIT-green">
</p>

## Features

- **23 conversion categories** - mass, length, temperature, area, volume, digital storage, time, speed, pace, pressure, energy, power, frequency, angle, currency and more.
- **Live currency rates**, fetched on demand.
- **Farsi-first** - full RTL layout, Persian digits by default, and an input parser that accepts Latin, Persian and Arabic-indic numerals.
- **Material 3 Expressive styling** — asymmetric tonal tiles, spring-physics press animations, and a pill-shaped swap button.
- **Responsive layout** — single-column on phones, an automatic two-pane layout on tablets, landscape, and unfolded foldables (≥ 600 logical px wide).
- **Configurable precision** — a settings sheet controls max decimal digits and Persian vs. Latin digit display.
- **Copy to clipboard** with one tap on the result.

## Tech stack

- **Flutter** (Material 3)
- [`google_fonts`](https://pub.dev/packages/google_fonts) — Vazirmatn, for proper Farsi typography
- [`http`](https://pub.dev/packages/http) — live currency rate fetching
- [`flutter_localizations`](https://docs.flutter.dev/ui/accessibility-and-localization/internationalization) — RTL + fa-IR locale

## Getting started

```bash
git clone https://github.com/omidshojaee/flutter_total_converter.git
cd flutter_total_converter
flutter pub get
flutter run
```

## Adding a new unit or category

Every category is defined in `converters.dart` relative to one hidden **base unit** (e.g. meters for length, kilograms for mass). Adding a unit is a single line:

```dart
Unit('mi', 'مایل', 'mi', 1609.344), // 1 mile = 1609.344 m (the base)
```

For non-linear relationships (temperature, pace), use `Unit.fn(...)` with explicit `toBase`/`fromBase` functions instead of a factor. See the comments in `converters.dart` for details.

## Currency data

Currency has **no offline fallback by design** — rates are fetched live from [open.er-api.com](https://www.exchangerate-api.com/) on open and via the refresh button. If the request fails, the app shows an error state with a retry action rather than a guessed number.

> ⚠️ The API returns the _official_ IRR rate, not an open-market rate. Swap the endpoint in `Currency.fetch()` if you need a different source.

## License

MIT — see [`LICENSE`](LICENSE).
