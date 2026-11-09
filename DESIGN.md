---
name: KKFC Multi-Brand POS
description: Tactile, high-throughput multi-brand point-of-sale and kitchen display system uniting counter hospitality with back-of-house culinary precision
colors:
  ground-canvas: "#F7F3EC"
  ground-sunken: "#EEE8DC"
  surface: "#FFFFFF"
  surface-subtle: "#FBF9F5"
  border: "#DDD6C9"
  border-strong: "#76849A"
  shell-navy: "#19293E"
  shell-raised: "#293F58"
  selected-navy: "#1D2940"
  selected-tint: "#E7ECF4"
  action-copper: "#A8562A"
  action-hover: "#8E4722"
  action-pressed: "#743A1B"
  action-tint: "#F9EBE2"
  accent-orange: "#FF9248"
  text-ink: "#19293E"
  text-ink-secondary: "#43536A"
  text-ink-muted: "#586579"
  brand-gamcheon: "#3D5A80"
  brand-aurelias: "#9A4A1F"
  brand-king-kungs: "#5C4033"
  status-neutral: "#46566C"
  status-info: "#1B5A96"
  status-review: "#5A3EA6"
  status-success: "#166B3A"
  status-warning: "#6A5200"
  status-danger: "#B3261E"
typography:
  display:
    fontFamily: "IBMPlexSansCondensed, sans-serif"
    fontSize: "30px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "0em"
  headline:
    fontFamily: "IBMPlexSansCondensed, sans-serif"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: 1.33
    letterSpacing: "0em"
  title:
    fontFamily: "IBMPlexSansCondensed, sans-serif"
    fontSize: "20px"
    fontWeight: 700
    lineHeight: 1.4
    letterSpacing: "0em"
  body:
    fontFamily: "AtkinsonHyperlegibleNext, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "0em"
  label:
    fontFamily: "AtkinsonHyperlegibleMono, monospace"
    fontSize: "13px"
    fontWeight: 600
    lineHeight: 1.38
    letterSpacing: "0.04em"
rounded:
  sm: "6px"
  md: "10px"
  lg: "14px"
  pill: "999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
  xxl: "48px"
components:
  button-primary:
    backgroundColor: "{colors.action-copper}"
    textColor: "#FFFFFF"
    rounded: "{rounded.md}"
    padding: "16px 24px"
    height: "56px"
  button-primary-hover:
    backgroundColor: "{colors.action-hover}"
    textColor: "#FFFFFF"
    rounded: "{rounded.md}"
    padding: "16px 24px"
    height: "56px"
  button-outlined:
    backgroundColor: "transparent"
    textColor: "{colors.text-ink}"
    rounded: "{rounded.md}"
    padding: "12px 20px"
    height: "48px"
  button-subtle:
    backgroundColor: "{colors.ground-sunken}"
    textColor: "{colors.text-ink}"
    rounded: "{rounded.md}"
    padding: "12px 20px"
    height: "48px"
  input-standard:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text-ink}"
    rounded: "{rounded.md}"
    padding: "16px 16px"
    height: "56px"
  card-resting:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text-ink}"
    rounded: "{rounded.md}"
    padding: "16px 16px"
  badge-status-success:
    backgroundColor: "#E3F4E9"
    textColor: "{colors.status-success}"
    rounded: "{rounded.pill}"
    padding: "4px 12px"
    height: "32px"
---

# Design System: KKFC Multi-Brand POS

## Overview

**Creative North Star: "The Precision Mess Hall"**

The KKFC Multi-Brand POS design system merges the mechanical precision of commercial kitchen gear with the warm hospitality and sensory delight of an active food hall. Built for high-volume retail environments where cashiers punch orders with rapid muscle memory and cooks monitor urgent order tickets through steam and grease, the interface rejects cold corporate tech aesthetics in favor of a grounded, physical visual language. Warm sand canvas grounds the experience, providing an organic, non-fatiguing backdrop where work sits comfortably over long shifts. Structural deep navy defines the application shell, navigation, and persistent selection states, while burnished copper acts as an unmistakable beacon for forward momentum—commanding the operator's eye to "do this next."

Interactive controls possess physical mass. Every button, menu card, and kitchen ticket provides responsive tactile feedback: an instant 90ms compression on press followed by a soft 5% spring overshoot on release. This tactile rhythm gives operators the confidence of mechanical switches while maintaining the speed and fluidity of a modern Android tablet. Front-of-House counter screens operate in a high-clarity Light Theme tuned for rapid touch-scanning under bright ambient lighting, while Back-of-House stations transition into a specialized high-contrast Dark Theme engineered for glare-free glanceability from across a crowded prep line.

The system explicitly rejects the tropes of generic SaaS: no sterile monochromatic enterprise blue fills, no fragile 1px hairline wireframes devoid of surface contrast, and no unstyled Material defaults. Multi-brand identity is celebrated with dignity—distinct brand accents for Gamcheon, Aurelia's Inasal, and King Kungs Kafé integrate smoothly into the unified shell without disturbing universal operational mechanics.

**Key Characteristics:**
- **Warm Earth & Industrial Marine Palette:** Warm Sand ground (#F7F3EC) paired with Deep Industrial Navy (#19293E) and Burnished Copper (#A8562A) action triggers.
- **Strict Semantic Color Assignment:** Copper exclusively for forward progress; Navy for structure and selection; Orange for shell alerts; status tones isolated from decoration.
- **Physical Tactile Feedback:** 48–56px generous touch targets, subtle ambient resting shadows, 0.97 scale press compression, and 280ms spring recovery.
- **Dual Environmental Themes:** High-clarity counter Light Mode alongside high-contrast Back-of-House KDS Dark Mode.
- **High-Velocity Tabular Readability:** Condensed display headers and slashed-zero tabular numbers guarantee instant data parsing across rapid scanning lines.

## Colors

The palette balances warm organic earth tones with industrial naval structure and calibrated functional status indicators, rigorously verified against WCAG 2.2 AA contrast standards.

### Primary
- **Burnished Copper** (#A8562A): The primary action catalyst. Reserved exclusively for forward-moving calls to action ("Add to Cart", "Send to Kitchen", "Submit QC"). Never used for passive selection or decorative highlights.
- **Deep Industrial Navy** (#19293E): The structural spine. Powers the top app bar, navigation rails, primary typography ink, and active selection containers (#1D2940). Communicates permanence, structure, and current location.

### Secondary
- **Warm Sand Canvas** (#F7F3EC): The physical ground where daily work sits. Provides a warm, low-glare surface that softens eye fatigue across long retail shifts.
- **Sunken Ground** (#EEE8DC): Recessed containers, stepper trays, and subtle button fills that sit one level below the active canvas.
- **Pure White Surface** (#FFFFFF): Elevated resting cards, input fields, and active dialog surfaces.

### Tertiary & Brand Accents
- **Gamcheon Slate Teal** (#3D5A80): Modern Korean dining brand accent, applied to brand tags, headers, and catalog chips.
- **Aurelia's Ember Rust** (#9A4A1F): Filipino Inasal brand accent, conveying smoky fire and traditional charcoal grilling.
- **King Kungs Roast Espresso** (#5C4033): Warm specialty café and beverage accent.

### Neutral & Ink
- **Deep Ink** (#19293E): High-contrast primary typography (13.30:1 contrast ratio against Warm Sand canvas).
- **Secondary Ink** (#43536A): Secondary descriptive text, category headers, and column labels (7.07:1 contrast ratio).
- **Muted Ink** (#586579): Helper text, timestamps, and inactive icons (5.34:1 contrast ratio).
- **Soft Oat Border** (#DDD6C9): Standard card and container outline stroke (1px).
- **Control Border Strong** (#76849A): Accessible 3:1 contrast boundary for input borders and outlined buttons.

### Status Indicators
- **Preparing Blue** (Ink #1B5A96 / Tint #E6F0FA / Border #A5C6E8): Active kitchen preparation and informative notices.
- **QC Review Violet** (Ink #5A3EA6 / Tint #F0ECFB / Border #C8BBEC): Quality check required, supervisor approvals, and pending reviews.
- **Ready Green** (Ink #166B3A / Tint #E3F4E9 / Border #9ED2B0): Order ready, QC passed, successful transaction.
- **Warning Gold** (Ink #6A5200 / Tint #FCF3CF / Border #DDBE55): Kitchen prep due soon, variance flags, modifier notes.
- **Danger Red** (Ink #B3261E / Tint #FCEBEA / Border #EDB3AF): Overdue ticket (>15 min), QC rework required, cancelled items.

### Named Rules
**The Strict Semantic Chromatic Rule.** Copper (#A8562A) is reserved solely for "do this next" primary forward actions; Navy (#19293E / #1D2940) owns selection, structure, and navigation; Orange (#FF9248) commands shell attention; status tones never act as decorative accents.

**The WCAG 2.2 AA Contrast Rule.** Every foreground/background pair must meet or exceed WCAG 2.2 AA (minimum 4.5:1 for body copy and 3.0:1 for essential graphical UI elements).

## Typography

The type system pairs condensed, mechanical data typography with an ultra-legible humanist reading face, guaranteeing split-second comprehension across bustling counters and steam-filled kitchen lines.

**Display & Numeric Font:** `IBMPlexSansCondensed` (self-hosted)
**Interface Body Font:** `AtkinsonHyperlegibleNext` (self-hosted)
**Monospace / Codes Font:** `AtkinsonHyperlegibleMono` (self-hosted)

**Character:** High-tempo mechanical efficiency softened by human-centered legibility. Condensed display numbers pack maximum price and timing data into compact cells, while Atkinson Hyperlegible guarantees unmistakable character distinction under harsh counter glare and distance viewing.

### Hierarchy
- **Display** (Bold 700, 30px, line-height 36px): Sign-in screens, major total banners, and primary summary metrics.
- **Headline** (Bold 700, 24px, line-height 32px): Page titles, brand headers, and prominent modal titles.
- **Title** (Bold 700, 20px, line-height 28px): Menu item names, cart card headings, and drawer titles.
- **Body** (Regular 400, 16px, line-height 24px): Standard POS counter body copy, descriptions, customer notes, and text field inputs (16px base prevents automated iOS/Android zoom shifts).
- **Body Medium** (Regular 400, 14px, line-height 20px): Secondary product modifiers, table cells, and receipt metadata.
- **Label / Meta** (SemiBold 600, 13px, letter-spacing 0.04em, line-height 18px): Status pill tags, badge text, tabular timestamps, and SKU codes.
- **Caption Minimum** (Regular 400, 12px, line-height 16px): Fine print, legal terms, and footer disclaimers.

### Operational KDS Scale (Viewed from 1 to 1.5 meters)
- **KDS Ticket Number** (Bold 700, 48px, line-height 52px, tabular): Massive order number legible from across the prep line.
- **KDS Elapsed Timer** (SemiBold 600, 32px, line-height 36px, tabular): Color-coded ticket duration timer.
- **KDS Item Name** (SemiBold 600, 24px, line-height 30px): Food item name on kitchen tickets.
- **KDS Modifier Text** (Medium 500, 18px, line-height 24px): Prep instructions, exceptions ("NO ONIONS"), and recipe variants.

### Named Rules
**The Tabular Number Rule.** All monetary values, quantities, order numbers, and elapsed timers must use tabular figures with slashed zeroes (`FontFeature.tabularFigures()`, `FontFeature.slashedZero()`) to preserve rigid vertical alignment across scanning columns.

**The Fixed Operational Scale Rule.** Type sizes on counter and kitchen terminals remain locked to fixed, predictable scale increments (~1.15 ratio) to prevent layout shifts and maintain muscle memory.

## Layout

The spatial model employs a strict 4-based spacing scale, scaling from compact 360dp Android mobile devices up to expansive 1600dp counter tablets and widescreen kitchen displays.

### Spacing Scale
- `space-1` (4px): Micro gaps between adjacent tags, pill padding, and icon margins.
- `space-2` (8px): Compact element spacing, padding inside chips, and dense table row padding.
- `space-3` (12px): Standard button horizontal padding, field padding, and card inset spacing.
- `space-4` (16px): Default screen margin on mobile, standard card interior padding, and form row gutters.
- `space-5` (20px): Section spacing and spacious card gutters.
- `space-6` (24px): Major component padding, modal headers, and tablet margin gutters.
- `space-8` (32px): Page section dividers and tablet split-screen gutters.
- `space-12` (48px): Spacious landing and empty-state margins.
- `space-16` (64px): Hero banners and desktop boundary padding.

### Breakpoints & Adaptive Surfaces
- **320px–360px (Android Phone / Small Terminal):** Single-column stacked flow. Bottom navigation bar with 3–5 destinations. Compact 48px header.
- **768px (Tablet Portrait):** Split view begins. Two-column menu grid. Kitchen Display displays 2×2 order lanes.
- **900px (POS Rail Threshold):** Persistent 96px vertical Navy Navigation Rail replaces bottom navigation. Sticky right-hand cart panel (400px width).
- **1024px+ (Tablet Landscape / Wide POS):** Three-column menu catalog. Kitchen Display transitions to horizontal multi-lane conveyor (minimum lane width 280px; max ticket width 340px).

### Touch Targets
- **POS Minimum Target (48×48 dp):** The absolute quality floor for any tappable element (chips, back buttons, modifier checkboxes).
- **POS Primary Target (56×56 dp):** Dedicated height for primary action buttons, keypads, and major checkout triggers.
- **Adjacent Target Clearance:** Minimum 8dp spacing between interactive touch zones.

### Named Rules
**The Thumbs & Fingers Rule.** Every primary interaction on counter tablets must sit comfortably within the 48–56px touch target zone with at least 8px clearance between adjacent hit targets.

## Elevation & Depth

The system uses a tactile, lifted depth model. Elements do not rely on excessive, fuzzy drop shadows; rather, cards sit with a crisp 1px border (`#DDD6C9`) complemented by a gentle ambient navy shadow that conveys physical lift. Interactive surfaces compress under touch, grounding digital actions in physical reality.

### Shadow Vocabulary
- **Shadow 1 (Subtle Ambient Lift):** `box-shadow: 0 1px 4px rgba(25, 41, 62, 0.06)`. Applied to resting cards, menu item tiles, and floating category pills.
- **Shadow 2 (Interactive Hover / Lift):** `box-shadow: 0 2px 8px rgba(25, 41, 62, 0.08), 0 1px 4px rgba(25, 41, 62, 0.04)`. Applied to hovered or active menu tiles and focused cards.
- **Shadow 3 (Overlays & Drawers):** `box-shadow: 0 8px 24px rgba(25, 41, 62, 0.14), 0 2px 8px rgba(25, 41, 62, 0.08)`. Applied to dialog modals, bottom sheets, slide-out carts, and notification toasts.

### Motion Grammar
- **Durations:**
  - `dur-press` (90ms): Instant mechanical feedback when finger strikes the screen.
  - `dur-micro` (150ms): Hover transitions, color shifts, and value counters.
  - `dur-exit` (140ms): Dismissals and closing sheets (always quicker than arrivals).
  - `dur-overlay` (220ms): Modal entries and drawer entrances.
  - `dur-screen` (240ms): Tab changes and cross-page navigation.
  - `dur-release` (280ms): Spring rebound when finger leaves the screen.
  - `dur-layout` (320ms): Cart panel expansion, drawer sliding, and kitchen ticket lane movements.
- **Curves:**
  - `ease-out`: Arrivals and element entrances (`Curves.easeOut`).
  - `ease-in`: Dismissals and exits (`Curves.easeIn`).
  - `ease-spring`: Soft physical spring (`cubic-bezier(0.34, 1.3, 0.64, 1.0)`) with 5% overshoot, reserved for confirmed order submissions, quantity increments, and button releases.

### Named Rules
**The Physical Compression Rule.** Interactive controls compress to 97% scale on press (90ms) and release with a soft 5% spring overshoot (280ms cubic-bezier(0.34, 1.3, 0.64, 1.0)), reinforcing tactile mechanical confirmation.

## Shapes

Shapes communicate purpose and hierarchy through rounded geometry, eliminating severe industrial sharpness while avoiding bubbly, toy-like forms.

- **Radius SM (6px):** Compact tags, nested stepper buttons, inner input controls, and secondary status badges.
- **Radius MD (10px):** Standard buttons, text fields, menu item cards, and container cards.
- **Radius LG (14px):** Major dialog containers, slide-out cart sheets, and primary kitchen ticket cards.
- **Radius Pill (999px):** Status badges, channel switcher tabs, toggle pills, and counter badges.
- **Borders & Outlines:** 1px solid stroke in Soft Oat (`#DDD6C9`) on light surfaces; raised navy stroke (`#293F58`) on kitchen dark surfaces. Active focus outlines render at 2–3px high-contrast blue (`#1F66C9`) on light and pale gold (`#FFC18E`) on navy shell.

### Named Rules
**The Nested Radius Rule.** Child elements nested inside 10px or 14px containers must scale down to 6px radius to maintain concentric optical harmony.

## Components

The component library emphasizes tactile feedback, high contrast, and rapid operational throughput.

### Buttons
- **Shape:** Rounded rectangle (10px radius); 48px standard height, 56px primary POS action height.
- **Primary:** Solid Burnished Copper (#A8562A) background with crisp White (#FFFFFF) bold text. Triggers "do this next" workflows.
- **Outlined:** Transparent surface with 1px Control Border Strong (#76849A) and Deep Ink (#19293E) text. Used for secondary actions ("Back", "Add Note").
- **Subtle:** Sunken Canvas (#EEE8DC) fill with Deep Ink text. Used for utility controls ("Edit Channels", "Clear Cart").
- **Ghost:** Borderless with Deep Ink text; used for non-essential inline actions.
- **Split Button:** Dual-compartment button pairing a primary label on the left with a dynamic badge or price on the right.
- **Touch States:** Compresses to 0.97 scale with background darkening (Copper Hover #8E4722 / Pressed #743A1B) on 90ms touch.

### Text Fields & Inputs
- **Style:** 56px POS input height, 10px corner radius, Pure White (#FFFFFF) fill with 1px border (#DDD6C9).
- **Focus:** 2px high-contrast focus ring in Focus Blue (#1F66C9) with clean transparent glow.
- **Numeric Field:** Integrated + / − steppers with tabular numerals, designed for rapid item count adjustments.
- **Search Field:** Leading search lens icon (#76849A), 16px body type, and instant trailing clear button.

### Status Badges
- **Style:** 32px height, fully rounded pill (999px radius), 4px 12px padding.
- **Variants:**
  - `Soft`: Tinted background, 1px matching border, high-contrast dark text (e.g. Success: #E3F4E9 bg, #9ED2B0 border, #166B3A text).
  - `Solid`: Opaque color fill with white text for critical alerts (e.g. Late: #B3261E bg, #FFFFFF text).
  - `Outlined`: White background with 1px border (#76849A) and secondary ink text.

### Menu Item Cards
- **Corner Style:** 10px radius with 1px border (#DDD6C9) and Shadow 1 lift.
- **Layout:** High-resolution product image thumbnail on the left or top, bold title (IBMPlexSansCondensed 18px), brand accent badge, item description (14px), and prominent tabular price badge (16px Bold).
- **Interactive State:** Hover lifts to Shadow 2; tap triggers immediate 0.97 press compression and spring release into cart.

### Signature Component: Kitchen Ticket Card
The central operational nexus of Back-of-House operations.
- **Structure:** 14px rounded container, dark theme surface (#141D2E), 1px raised border (#293F58). Width: 280–340px.
- **Header:** Full-width color-coded aging bar:
  - *On Time (0–5 min):* Green tint (#166B3A)
  - *Due Soon (5–8 min):* Amber Gold tint (#6A5200)
  - *Late (8+ min):* Danger Red flash (#B3261E)
- **Ticket Metadata:** 48px massive bold order number (e.g. "#104"), brand code pill ("GC", "AI", "KK"), order channel tag ("Dine-in", "Takeout"), and tabular running stopwatch.
- **Item Checklist:** 18px list of ordered dishes with clear checkbox targets; modifiers highlighted in bold warning tint ("NO MAYO").
- **Footer:** Full-width action button ("Begin Prep" -> "Quality Check" -> "Hand Over").

## Do's and Don'ts

### Do:
- **Do** maintain strict 48×48 dp minimum touch targets across all interactive POS and KDS elements.
- **Do** reserve Burnished Copper (#A8562A) strictly for primary forward-moving calls to action.
- **Do** format all currency, timers, and quantities using `IBMPlexSansCondensed` or `AtkinsonHyperlegibleMono` with tabular figures and slashed zero.
- **Do** compress interactive elements to 0.97 scale on 90ms touch press and spring back with 5% overshoot.
- **Do** use high-contrast Dark Theme for Kitchen Display System screens to preserve glanceability and reduce glare in kitchen environments.
- **Do** honor individual brand colors (Gamcheon Slate Teal, Aurelia's Ember Rust, King Kungs Roast Espresso) on brand badges and category indicators without breaking unified navigation.

### Don't:
- **Don't** use Burnished Copper for selected tabs, checkboxes, or non-action elements (use Navy #1D2940 instead).
- **Don't** ship thin, unstyled 1px hairline cards without ambient depth or surface contrast.
- **Don't** create floating or stacked Floating Action Buttons (FABs); follow dedicated 56px action button bars.
- **Don't** use fluid typography on POS terminals; maintain fixed rem scale sizes (~1.15 ratio) to avoid operational mis-clicks.
- **Don't** display raw, un-padded numbers in financial or ticket data; always use tabular font features.
- **Don't** use generic cold blue SaaS enterprise styling; preserve the warm organic sand ground and industrial marine character.
