# Purina iOS App — Refactoring Instructions

Full-app refactor and UI modernization, following `REFACTOR_PLAN.md`. These instructions apply to every screen and layer, not just Home — Home was the pilot and is now the reference implementation for the patterns below.

## Scope

- Execute in phase order: foundation (Coordinator navigation, MVVM scaffolding, service protocols over legacy state, DesignSystem v2, shared components, test harness) before screen-by-screen migration, before consolidation, before hardening. Don't build a screen's UI on top of foundation pieces that don't exist yet.
- Within screen migration, follow this flow-group order unless the user names another screen or flow explicitly: Home → Device connection & scanning → DFU update flow → Device data screens (Channels/LND family) → Charts & scrolling data views → Files/logs/text views → Remaining utility screens.
- Preserve existing BLE packet parsing, command generation, notification setup, and file-writing behavior exactly, in every phase, unless a change is explicitly requested.

## Platform

- iOS 15.6 minimum deployment target; keep all touched code compatible.
- UIKit remains the shell for every screen. SwiftUI may only be used for new, fully isolated components embedded via `UIHostingController` where it clearly reduces code — never as a wholesale screen rewrite.

## Architecture

Target pattern for every screen touched from here on: formal MVVM + Coordinator, replacing storyboard-segue routing and business logic living in view controllers.

- **Navigation:** goes through Coordinators, not view controllers pushing other view controllers or triggering segues directly. Root `AppCoordinator`, with per-flow coordinators matching the flow groups above (e.g. `HomeCoordinator`, `ConnectionCoordinator`, `DFUCoordinator`, `DeviceDataCoordinator`, `FilesCoordinator`). `HomeRouter` is promoted into `HomeCoordinator` rather than kept as a separate, older pattern.
- **View models:** every screen gets one. View controllers are binding + layout only — no business logic, no direct service/singleton access.
- **Binding style:** plain closures (input closures the view controller calls, output closures/callbacks the view controller assigns) — no Combine, no third-party reactive framework. This keeps the foundation dependency-free and directly testable with XCTest, consistent with the codebase's current lack of any reactive framework. Revisit only if a clear need for reactive composition emerges later.
- **Legacy state:** all access to `Utils.m` and `.shared` singletons goes through small protocol-based services (e.g. `BLEConnectionServicing`, `BLECommandServicing`, `DeviceFileWriting`, `DeviceLoggingServicing`). New or touched code must not add new direct singleton or `Utils.m` call sites — route through or extend a service protocol instead. `Utils.m` internals stay unchanged until the consolidation phase explicitly targets them.
- **Dependency injection:** use a simple constructor-injected `AppDependencies` container to hand coordinators and view models their services, instead of each type reaching for a singleton itself.
- Prefer one canonical implementation for shared UI types and shared BLE-adjacent helpers (chart containers, dropdown pickers, action-button rows, connection headers, alerts). Never duplicate `DesignSystem`, buttons, chips, table cells, or alert helpers across files.
- Preserve storyboard identifiers and destination behavior while refactoring; coordinators may still instantiate storyboard scenes internally.
- For BLE/charting screens, extract setup and state helpers before changing packet parsing, command generation, or file-writing behavior.

## Design (DesignSystem v2)

- DesignSystem v2 supersedes the current v1 tokens with a fresher, more distinctive visual direction, defined once as an approved proposal and then applied consistently everywhere — no per-screen reinvention, and no mixing v1/v2 tokens within one screen.
- Source colors, typography, spacing, radius, shadows, motion, and haptics from `DesignSystem` — no hardcoded values in screen code.
- Support light and dark mode, and Dynamic Type, on every migrated screen.
- Use SF Symbols for feature icons when available, with existing asset fallbacks.
- Avoid decorative UI that doesn't improve comprehension or task speed; restrained and professional, but visually distinctive rather than generic.

## Quality

- Avoid force unwraps in new or touched code, in Swift or in new Swift wrappers around Objective-C.
- Prefer `private` access for implementation details; use descriptive names and small methods.
- Every extracted service protocol and every new view model gets a real XCTest unit test (with a mock/fake dependency) at the point it's extracted, not deferred to a later "testing phase."
- BLE-critical flows (connection, DFU, live device data) additionally get a manual hardware regression pass before being considered done — unit tests can't fully cover real hardware behavior.
- Add comments only for non-obvious behavior, especially BLE compatibility constraints.
- Validate each focused change with Xcode diagnostics and a full build before considering it complete.

## Consolidation

- Before merging any screens flagged as possible duplicates (`Channels`/`Channels2`, `LND`/`LND2`/`LND339`, `Scroll`/`Scroll2`, `PPGOldViewController` and newer PPG code), confirm whether each is a true duplicate or a distinct device/firmware variant. Document the decision in a code comment rather than leaving it ambiguous.
- Remove dead code, unused pods, and leftover v1 DesignSystem tokens only after the screens/areas depending on them are fully migrated.
