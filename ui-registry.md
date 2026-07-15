# UI Registry — Portea Flutter

> Établi via `/imprint audit` — 2026-07-15
> Construit depuis l'analyse de `app_colors.dart`, `app_text_styles.dart`, `app_theme.dart` et des screens existants.

---

## Baseline — Établi 2026-07-15

Note: ce baseline a été établi via l'audit du design system existant.

### Palette de couleurs (tokens)

| Token | Valeur | Usage |
|-------|--------|-------|
| `AppColors.primary` | `#C4664A` (terracotta) | Boutons primaires, liens, accents |
| `AppColors.primaryDark` | `#993C1D` | Hover / dark mode accent |
| `AppColors.primaryLight` | `#FAECE7` | Fond indicateur nav, fond tag léger |
| `AppColors.background` | `#FAF6F2` | Scaffold background (light) |
| `AppColors.surface` | `#FFFFFF` | Cards, inputs (light) |
| `AppColors.border` | `#EAE2D9` | Bordures (light) |
| `AppColors.textPrimary` | `#2C2C2A` | Texte principal (light) |
| `AppColors.textSecondary` | `#948A80` | Texte secondaire, hints (light) |
| `AppColors.darkBackground` | `#121212` | Scaffold background (dark) |
| `AppColors.darkSurface` | `#1E1E1E` | Cards, inputs (dark) |
| `AppColors.darkBorder` | `#2C2C2C` | Bordures (dark) |
| `AppColors.darkTextPrimary` | `#E5E5E5` | Texte principal (dark) |
| `AppColors.darkTextSecondary` | `#8E8E93` | Texte secondaire (dark) |
| `AppColors.premium` | `#EF9F27` | Or/amber — éléments premium |
| `AppColors.error` | `#E24B4A` | Erreurs |
| `AppColors.female` | `#D4537E` | Badge femelle |
| `AppColors.male` | `#378ADD` | Badge mâle |

### Typographie (NunitoSans via Google Fonts)

| Style | Taille | Poids | Usage |
|-------|--------|-------|-------|
| `AppTextStyles.screenTitle` | 24sp | Bold | Titre principal d'écran (h1) |
| `AppTextStyles.sectionTitle` | 18sp | Bold | Titre de section dans un écran |
| `AppTextStyles.body` | 15sp | Regular | Texte de corps, descriptions |
| `AppTextStyles.captionLabel` | 13sp | Regular | Labels, captions, sous-titres |
| Navigation labels | 12sp | Regular / Bold | Labels barre navigation |

**Police** : NunitoSans exclusivement (Google Fonts). INTERDIT : autre police.

### Cards

| Propriété | Valeur |
|-----------|--------|
| Background (light) | `AppColors.surface` (#FFFFFF) |
| Background (dark) | `AppColors.darkSurface` (#1E1E1E) |
| Border | `AppColors.border` (#EAE2D9) / `AppColors.darkBorder` (#2C2C2C) |
| Border width | 0.5 |
| Border radius | 16px |
| Elevation | 0 |
| Margin | EdgeInsets.zero (géré par le parent) |

**Pattern note** : utiliser `Card` de Material3 qui reprend le `cardTheme` du thème. Ne pas overrider le style inline.

### Boutons primaires (ElevatedButton)

| Propriété | Valeur |
|-----------|--------|
| Background | `AppColors.primary` (#C4664A) |
| Foreground | Colors.white |
| Min height | 52px |
| Border radius | 14px |
| Elevation | 0 |
| Texte | 16sp, Bold, NunitoSans |

**Pattern note** : toujours `ElevatedButton` pour l'action principale d'un écran. Utiliser `minimumSize: Size.fromHeight(52)` pour les boutons pleine largeur.

### TextButton (actions secondaires)

| Propriété | Valeur |
|-----------|--------|
| Foreground | `AppColors.primary` |
| Texte | 15sp, Bold, NunitoSans |

### Inputs (TextFormField / TextField)

| Propriété | Valeur |
|-----------|--------|
| Fill | `AppColors.surface` (light) / `AppColors.darkSurface` (dark) |
| Border radius | 12px |
| Border (enabled) | `AppColors.border` / `AppColors.darkBorder` |
| Border (focused) | `AppColors.primary`, width 1.5 |
| Border (error) | `AppColors.error` |
| Padding | h16 + v16 |
| Label style | 15sp, `AppColors.textSecondary` |
| Hint style | 15sp, `AppColors.textSecondary` |

### AppBar

| Propriété | Valeur |
|-----------|--------|
| Background | `AppColors.background` (light) / `AppColors.darkBackground` (dark) |
| Elevation | 0 |
| Title alignment | Left (centerTitle: false) |
| Icon color | `AppColors.textPrimary` (light) / `AppColors.darkTextPrimary` (dark) |

### Scaffold / layout

| Propriété | Valeur |
|-----------|--------|
| Background | `AppColors.background` (light) / `AppColors.darkBackground` (dark) |
| Padding horizontal standard | 24px |
| Padding vertical standard | 16px |
| Max width container | 600-650px (ConstrainedBox sur les formulaires) |

### Status badges (StatusBadgeWidget)

| Status | Background | Text | Border |
|--------|-----------|------|--------|
| available | `statusAvailableBg` (#EAF3DE) | `statusAvailableText` (#27500A) | `statusAvailable` (#639922) |
| reserved | `statusReservedBg` (#FAEEДА) | `statusReservedText` (#633806) | `statusReserved` (#BA7517) |
| sold | `statusSoldBg` (#E6F1FB) | `statusSoldText` (#0C447C) | `statusSold` (#185FA5) |

---

## Conflits identifiés lors de l'audit

### Hardcoded colors (à surveiller)

- `OnboardingWelcomeScreen` ligne 27 : `color: Color(0xFFC4664A)` — DOIT utiliser `AppColors.primary`
- `KennelSetupScreen` ligne 26 : `AppColors.primaryDark.withValues(alpha: 0.25)` — usage correct (variante opacity)

### Recommandation

Tout `Color(0x...)` inline doit être remplacé par le token `AppColors.*` correspondant.
À corriger en F01 lors de la refonte de l'onboarding.

---

## Composants recensés

### OnboardingWelcomeScreen
File: `lib/features/onboarding/presentation/screens/onboarding_welcome_screen.dart`
Last updated: 2026-07-15

| Propriété | Valeur |
|-----------|--------|
| Background | Scaffold → `AppColors.background` |
| Icône principale | `Icons.pets_rounded`, 96px, **⚠️ Color(0xFFC4664A) hardcodé** |
| Titre | `AppTextStyles.screenTitle` |
| Sous-titre | `AppTextStyles.body` + `AppColors.textSecondary` adaptatif |
| Bouton | `ElevatedButton` standard |
| Padding | h24 + v32 |

### KennelSetupScreen
File: `lib/features/onboarding/presentation/screens/kennel_setup_screen.dart`
Last updated: 2026-07-15

| Propriété | Valeur |
|-----------|--------|
| Background | Scaffold → `AppColors.background` |
| Titre section | `AppTextStyles.sectionTitle` |
| Sous-titre | `AppTextStyles.captionLabel` |
| Inputs | `TextFormField` → InputDecorationTheme du thème |
| Padding | h24 + v16 |
| Max width | 650px |
| Species selector | Container custom : border `AppColors.border` / `AppColors.darkBorder`, radius 12, fond `AppColors.primaryLight` si sélectionné |

**Pattern note** : les sélecteurs d'options (species, sex) utilisent un `Container` avec border + fond coloré sur sélection, pas un `ChoiceChip`. Reproduire ce pattern pour toute sélection d'option exclusive.

### SettingsScreen
File: `lib/features/settings/presentation/screens/settings_screen.dart`
Last updated: 2026-07-15

| Propriété | Valeur |
|-----------|--------|
| Sections | `AppTextStyles.sectionTitle` + `Divider` entre sections |
| Inputs | `TextFormField` standard |
| Actions | `ElevatedButton` pleine largeur |
| Premium badge | Chip amber (`AppColors.premium`) dans la barre titre |

---

## Règles d'usage pour les futures sessions

1. **Police** : NunitoSans UNIQUEMENT via `AppTextStyles.*`. Jamais de `TextStyle(fontFamily: 'xxx')` inline.
2. **Couleurs** : `AppColors.*` UNIQUEMENT. Jamais de `Color(0x...)` inline.
3. **Cards** : utiliser `Card` Material3 — ne pas recreer un container avec border manuellement.
4. **Boutons** : `ElevatedButton` (action principale), `TextButton` (action secondaire), `OutlinedButton` (action tertiaire).
5. **Spacing** : 8px (micro), 16px (standard), 24px (section), 32px (section large).
6. **Border radius** : 12px (inputs), 14px (boutons), 16px (cards), 12px (conteneurs option).
7. **Adaptation dark mode** : toujours tester les 2 thèmes. Utiliser `Theme.of(context).brightness == Brightness.dark` pour les overrides ponctuels (pattern du repo).
