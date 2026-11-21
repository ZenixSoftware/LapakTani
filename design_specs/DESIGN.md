---
name: LapakTani Agri-Commerce
colors:
  primary: '#388E5C'
  primary-dark: '#2E754C'
  primary-tint: '#EFF6F1'
  primary-border: '#CFE3D6'
  secondary: '#2B7A9E'
  secondary-dark: '#22627F'
  secondary-tint: '#EAF3F7'
  secondary-border: '#C9E0EA'
  tertiary: '#E5A93B'
  tertiary-text: '#8A5E00'
  tertiary-tint: '#FDF6EA'
  tertiary-border: '#F3DDB0'
  neutral: '#3D3228'
  neutral-muted: '#6E6259'
  neutral-subtle: '#A39890'
  neutral-border: '#D8CFCA'
  border: '#E2E8E4'
  surface-card: '#FFFFFF'
  surface-canvas: '#F8FAF6'
  error: '#C94A29'
  error-tint: '#FBEDE9'
  error-border: '#F0C3B6'
typography:
  display:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 40px
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '700'
    lineHeight: 24px
  title-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 22px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 14px
rounded:
  sm: 4px
  DEFAULT: 8px
  md: 12px
  lg: 16px
  xl: 24px
  full: 9999px
spacing:
  space-xs: 4px
  space-sm: 8px
  space-md: 12px
  space-lg: 16px
  space-xl: 24px
  space-2xl: 32px
---

# LapakTani Agri-Commerce Design System

## 1. Brand & Style

LapakTani uses a Tokopedia-style **White-Dominant Clean Agri-Commerce** aesthetic across both Web Portal (`lapaktani_web`) and Mobile App (`lapaktani_app`). Approximately 80% of every viewport is pure white (`#FFFFFF`) card/header surfaces and soft botanical canvas (`#F8FAF6`), structured by crisp thin borders (`#E2E8E4` / `#D8CFCA`) and flat cards with zero neon or pink clutter.

- **Single Source of Truth:** Updating any core token in `:root` (`lapaktani_web/src/index.css`) or `AppColors` (`lapaktani_app/lib/core/theme/app_colors.dart`) re-themes the entire respective platform.
- **Visual Hierarchy:** Content clarity and outdoor daylight legibility come first, anchored by warm fertile-soil charcoal (`#3D3228`) instead of harsh black.

## 2. Colors

### 4 Core Agrarian Palette Roles

1. **`primary` (`#388E5C` — Hijau Soft / Nature Foliage)**
   - Derived: `primary-dark` (`#2E754C` hover/pressed), `primary-tint` (`#EFF6F1`), `primary-border` (`#CFE3D6`).
   - Usage: Main CTA buttons, active tabs/nav pills, primary brand logo, fresh guarantee badges.
2. **`secondary` (`#2B7A9E` — Biru Air / Irigasi)**
   - Derived: `secondary-dark` (`#22627F`), `secondary-tint` (`#EAF3F7`), `secondary-border` (`#C9E0EA`).
   - Usage: Cold-chain logistics, IoT telemetry, secondary actions, B2B/PPL verification badges.
3. **`tertiary` (`#E5A93B` — Kuning Padi Panen)**
   - Derived: `tertiary-text` (`#8A5E00` text-safe on light surfaces), `tertiary-tint` (`#FDF6EA`), `tertiary-border` (`#F3DDB0`).
   - Usage: Star ratings, harvest lot quota progress, warning/promo highlights.
4. **`neutral` (`#3D3228` — Cokelat Tanah Subur)**
   - Derived: `neutral-muted` (`#6E6259`), `neutral-subtle` (`#A39890` hints/disabled), `neutral-border` (`#D8CFCA`).
   - Usage: High-contrast headings, body copy, outlines, neutral icons.

### Surfaces & Semantic Guard

- **`surface-card` (`#FFFFFF`):** Dominant card, app bar, sidebar, and modal surface.
- **`surface-canvas` (`#F8FAF6`):** Subtle botanical page/scaffold background.
- **`border` (`#E2E8E4`):** Hairline container and table borders.
- **`error` (`#C94A29`):** Derived `error-tint` (`#FBEDE9`), `error-border` (`#F0C3B6`). Strictly reserved for form validation errors, destructive actions, and critical soil alerts.

### Derived Tokens Notice

Tokens marked derived (`primary-border`, `secondary-dark`, `secondary-border`, `tertiary-border`, `error-tint`, `error-border`, `neutral-subtle`) are tonal companions calculated from the 4 core roles and surface tokens to guarantee crisp hairline borders and accessible tinted fills.

### WCAG Contrast Rules

- **NEVER** render `tertiary` (`#E5A93B`) as text on `surface-card` (`#FFFFFF`), `surface-canvas` (`#F8FAF6`), or `tertiary-tint` (`#FDF6EA`). Always use `tertiary-text` (`#8A5E00`) for gold/amber text and text-like icons on light backgrounds.
- On a solid `tertiary` (`#E5A93B`) surface, foreground text MUST be `neutral` (`#3D3228`), never white.
- Text on `primary`, `primary-dark`, `secondary`, `secondary-dark`, `neutral`, or `error` solid surfaces uses `#FFFFFF`.

## 3. Typography

- **Font Family:** `Plus Jakarta Sans` uniformly across Web and Flutter (`GoogleFonts.plusJakartaSans` in Flutter, Google Fonts / `@fontsource` in Web).
- **Scale:** `display` (32/40, 800), `headline-lg` (24/32, 700), `headline-md` (20/28, 700), `headline-sm` (16/24, 700), `title-md` (15/22, 600), `body-lg` (16/24, 400), `body-md` (14/20, 400), `body-sm` (12/16, 400), `label-md` (12/16, 600), `label-sm` (10/14, 700).

## 4. Layout & Spacing

- **Mobile Base (360dp viewport):** Single-column fluid layout with `16px` (`space-lg`) horizontal outer margins and `12px` (`space-md`) grid gutters. Minimum touch targets of `48dp` height for primary buttons and list controls.
- **Web Portal:** Clean white sidebar (`256px`–`288px`) + white sticky header + `surface-canvas` main workspace (`#F8FAF6`).
- **Spacing Scale:** `4px` (`space-xs`), `8px` (`space-sm`), `12px` (`space-md`), `16px` (`space-lg`), `24px` (`space-xl`), `32px` (`space-2xl`).

## 5. Elevation & Depth

- Flat, airy surfaces separated by `1px solid border` (`#E2E8E4`).
- Shadows are subtle and warm-tinted (`rgba(61, 50, 40, 0.06)` max `0 1px 3px rgba(61, 50, 40, 0.06)` for resting cards). No heavy drop shadows or glowing overlays.

## 6. Components

- **Buttons:**
  - *Primary:* Solid `primary` (`#388E5C`), `#FFFFFF` bold text, hover `primary-dark` (`#2E754C`), radius `8px`–`12px`.
  - *Secondary / Outline:* `surface-card` (`#FFFFFF`) background, `1px` `primary` or `secondary` border, matching text.
  - *Destructive:* Solid `error` (`#C94A29`) or `error-tint` with `error` text/border.
- **Cards:** `surface-card` (`#FFFFFF`), `1px solid border` (`#E2E8E4`), `16px` (`lg`) corner radius, `16px` inner padding.
- **Navigation & Sidebar Active Pill:** `primary-tint` (`#EFF6F1`) background with `primary` (`#388E5C`) bold text and icon. Inactive items use `neutral-muted` (`#6E6259`).
- **Chips & Badges:** Pill-shaped (`9999px`) or `8px` rounded; `primary-tint`/`primary` for verified freshness, `secondary-tint`/`secondary` for IoT & PPL badges, `tertiary-tint`/`tertiary-text` for quota & promo highlights, `error-tint`/`error` for critical alerts.
- **Inputs:** `surface-card` (`#FFFFFF`) fill, `1px` `border` (`#E2E8E4`), focus ring `primary` (`#388E5C`), error border `error` (`#C94A29`).

## 7. Web & Flutter Token Mapping

| Canonical Token | Hex | CSS Variable (`index.css`) | Tailwind Utility Prefix | Flutter (`AppColors.*`) |
|---|---|---|---|---|
| `primary` | `#388E5C` | `--lt-primary` | `*-lt-primary` | `AppColors.primary` |
| `primary-dark` | `#2E754C` | `--lt-primary-dark` | `*-lt-primary-dark` | `AppColors.primaryDark` |
| `primary-tint` | `#EFF6F1` | `--lt-primary-tint` | `*-lt-primary-tint` | `AppColors.primaryTint` |
| `primary-border` | `#CFE3D6` | `--lt-primary-border` | `*-lt-primary-border` | `AppColors.primaryBorder` |
| `secondary` | `#2B7A9E` | `--lt-secondary` | `*-lt-secondary` | `AppColors.secondary` |
| `secondary-dark` | `#22627F` | `--lt-secondary-dark` | `*-lt-secondary-dark` | `AppColors.secondaryDark` |
| `secondary-tint` | `#EAF3F7` | `--lt-secondary-tint` | `*-lt-secondary-tint` | `AppColors.secondaryTint` |
| `secondary-border` | `#C9E0EA` | `--lt-secondary-border` | `*-lt-secondary-border` | `AppColors.secondaryBorder` |
| `tertiary` | `#E5A93B` | `--lt-tertiary` | `*-lt-tertiary` | `AppColors.tertiary` |
| `tertiary-text` | `#8A5E00` | `--lt-tertiary-text` | `*-lt-tertiary-text` | `AppColors.tertiaryText` |
| `tertiary-tint` | `#FDF6EA` | `--lt-tertiary-tint` | `*-lt-tertiary-tint` | `AppColors.tertiaryTint` |
| `tertiary-border` | `#F3DDB0` | `--lt-tertiary-border` | `*-lt-tertiary-border` | `AppColors.tertiaryBorder` |
| `neutral` | `#3D3228` | `--lt-neutral` | `*-lt-neutral` | `AppColors.neutral` |
| `neutral-muted` | `#6E6259` | `--lt-neutral-muted` | `*-lt-neutral-muted` | `AppColors.neutralMuted` |
| `neutral-subtle` | `#A39890` | `--lt-neutral-subtle` | `*-lt-neutral-subtle` | `AppColors.neutralSubtle` |
| `neutral-border` | `#D8CFCA` | `--lt-neutral-border` | `*-lt-neutral-border` | `AppColors.neutralBorder` |
| `border` | `#E2E8E4` | `--lt-border` | `*-lt-border` | `AppColors.border` |
| `surface-card` | `#FFFFFF` | `--lt-surface-card` | `*-lt-surface-card` | `AppColors.surfaceCard` |
| `surface-canvas` | `#F8FAF6` | `--lt-surface-canvas` | `*-lt-surface-canvas` | `AppColors.surfaceCanvas` |
| `error` | `#C94A29` | `--lt-error` | `*-lt-error` | `AppColors.error` |
| `error-tint` | `#FBEDE9` | `--lt-error-tint` | `*-lt-error-tint` | `AppColors.errorTint` |
| `error-border` | `#F0C3B6` | `--lt-error-border` | `*-lt-error-border` | `AppColors.errorBorder` |
