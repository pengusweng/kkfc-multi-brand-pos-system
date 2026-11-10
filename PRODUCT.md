# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users
- **Cashiers and Counter Staff (Front-of-House):** Fast-paced counter environment handling walk-in customers and delivery/takeout pickups. Primary tasks include rapid order creation, multi-brand item selection, modifiers and customization, channel-specific repricing (Dine-in, Takeout, Delivery), cart management, and order handoff.
- **Kitchen Staff & Kitchen Heads (Back-of-House):** High-tempo kitchen environment managing order preparation. Primary tasks include real-time ticket tracking on Kitchen Display System (KDS), acknowledging preparation states (queued, preparing, ready), managing ticket urgency/aging, quality check (QC) verification, rework handling, and final order handoff.
- **Store Managers & Supervisors:** Monitoring multi-brand sales, catalog availability, menu status, inventory, and kitchen throughput.

## Product Purpose
KKFC POS (Accela POS) is a multi-brand Point-of-Sale and Kitchen Display System designed to streamline food and beverage operations across multiple distinct restaurant brands operating under one roof. It eliminates operational friction between front-of-house order taking and back-of-house food preparation, ensuring fast order throughput, accurate ticket fulfillment, and consistent multi-brand brand identity.

## Positioning
Unlike single-brand POS systems that require separate terminals or clunky account switching for shared multi-concept kitchens, KKFC POS natively supports multi-brand ordering, brand-specific styling and menus, and shared kitchen ticket routing in a single unified interface.

## Operating Context
- **Counter / POS Terminals:** Android tablets and touchscreen terminals operating in high-volume, continuous counter environments. Cashiers require responsive, high-contrast touch interactions (minimum 48×48 dp touch targets), rapid brand switching, and clear channel repricing visibility.
- **Kitchen Display System (KDS):** Wall-mounted or station-mounted Android displays operating in a dedicated dark theme to reduce eye fatigue and maximize glanceability under kitchen lighting conditions. Color-coded ticket aging (on time, due soon, late) and clear status tags drive time-sensitive kitchen operations.

## Capabilities and Constraints
- **Multi-Brand Catalog:** Supports distinct brands (Gamcheon, Aurelia's Inasal, King Kungs Kafe) with separate menus, items, categories, and modifiers.
- **Dynamic Channel Repricing:** Automatic price adjustments based on order channel (Dine-in, Takeout, Delivery).
- **Kitchen Ticket Lifecycle:** State management spanning ticket queue, preparation in-progress, QC pass/fail with photo capture and rework flow, and handoff confirmation.
- **Dual Visual Modes:** Counter POS runs in high-clarity Light Theme; Kitchen Display runs in specialized high-contrast Dark Theme.
- **Technical Stack:** Flutter mobile/tablet client targeting Android hardware; backend REST API powered by Node.js/NestJS, TypeORM/Prisma, PostgreSQL database, and private AWS S3 asset storage.

## Brand Commitments
- **Gamcheon (`GC`):** Modern Korean-inspired brand aesthetic with brand accent `#3D5A80`.
- **Aurelia's Inasal (`AI`):** Filipino Inasal brand aesthetic with brand accent `#9A4A1F`.
- **King Kungs Kafe (`KK`):** Specialty cafe & beverage aesthetic with brand accent `#5C4033`.
- **Brand Typography:** Bundled type families: `IBMPlexSansCondensed` for condensed display/data hierarchy, `AtkinsonHyperlegibleNext` for legible UI text, and `AtkinsonHyperlegibleMono` for monospace data, tickets, and numeric values.

## Evidence on Hand
- Fully specified feature specs under `features/` covering `brands`, `orders`, `kitchen`, `menu`, `modifiers`, `auth`, `users`, and `assets`.
- Comprehensive Flutter test suite under `mobile/test/` with Alchemist golden visual regression baselines (`mobile/test/**/goldens/ci/*.png`).
- Core theme tokens and semantic color definitions implemented in `mobile/lib/app/theme/`.

## Product Principles
1. **Speed and Efficiency First:** Minimize taps and eliminate latency for counter order entry; ensure immediate glanceability and status recognition on kitchen tickets.
2. **Context-Driven Visual Modes:** Light mode optimized for counter scanning; dark mode optimized for kitchen stations and glanceable ticket aging.
3. **Fail-Safe Kitchen Fulfillment:** Never lose ticket state during network or operational turbulence; provide explicit visual validation for quality check and rework handoffs.
4. **Authentic Multi-Brand Coexistence:** Respect each brand's distinct identity and color accent while maintaining strict cross-brand structural consistency.

## Accessibility & Inclusion
- Strict touch target sizing (minimum 48×48 dp) for reliable counter and kitchen terminal input.
- High-contrast typography utilizing Atkinson Hyperlegible typefaces to optimize legibility under varied lighting.
- Redundant status communication pairing color indicators with explicit text labels and status icons for accessibility.
