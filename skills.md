# Purina iOS App — Refactor Workflow & Checklists

Companion to `instructions.md` and `REFACTOR_PLAN.md`. Home screen's `HomeRouter` / `HomeConnectionState` / `BluetoothConnectionService` work was the pilot for these patterns — Home now gets promoted onto the full Coordinator/MVVM foundation alongside every other screen.

## General Refactor Workflow (every change)

1. Read the existing files before editing.
2. Confirm which files are included in `Purina.xcodeproj` — don't assume a similarly-named file is unused.
3. Identify which phase (per `REFACTOR_PLAN.md`) the work belongs to and confirm its prerequisites exist — e.g. don't build a screen's view model before its flow's Coordinator exists.
4. Remove or consolidate duplicate UI/component definitions before adding new polish.
5. Make focused changes that preserve behavior.
6. Run Xcode live diagnostics for edited Swift files.
7. Run a full Xcode build after each phase or screen.
8. Add or update unit tests for anything extracted (service protocol, view model) as part of the same change, not as a follow-up.

## Foundation Phase Skills

- **Coordinator:** define a `Coordinator` protocol (start, child coordinators, navigation controller reference) before creating the first concrete coordinator. Promote `HomeRouter` into `HomeCoordinator` as the reference implementation others follow.
- **View models:** define the input/output closure convention once and reuse it for every screen — don't invent a new binding style per screen.
- **Service extraction from `Utils.m` / singletons:** work one responsibility area at a time (connection, command/packet, file writing, logging). Define a small protocol for it, implement it as a thin wrapper over the existing global/`Utils.m` call with no internal behavior change, inject it via `AppDependencies`, and write a unit test using a fake conforming to the protocol.
- **DesignSystem v2:** implement approved tokens additively alongside v1 until a screen is ready to fully migrate; never mix v1 and v2 tokens within the same screen.
- **Shared components:** before extracting a component, check `Channels`/`Channels2`, `LND`/`LND2`/`LND339`, `Scroll`/`Scroll2`, and the DFU screens for the same pattern, so the extracted version covers every existing use rather than just the first one found.

## Screen Migration Skills

- Follow flow-group order from `REFACTOR_PLAN.md`: Home → Connection/Scanning → DFU → Device Data (Channels/LND family) → Charts/Scrolling Data → Files/Logs/Text → Remaining Utility Screens. Pick screens within a group in Home-menu order unless the user names another screen.
- Per screen: extract a view model, route it through its flow's coordinator, replace legacy singleton/`Utils.m` access with foundation-phase service protocols, apply DesignSystem v2 and shared components, remove force-unwraps in touched code, add unit tests for the new view model and any BLE-adjacent logic extracted, then validate with a build and the UI Review Checklist below.
- Keep BLE command bytes, packet parsing, notification setup, and file-writing semantics unchanged during architecture/UI passes — those changes are out of scope unless explicitly requested.
- Extract repeated setup into methods such as `configureChart`, `configureDropdowns`, `configureActionButtons`, and state helpers.
- Replace repeated alerts with the one shared alert helper from the foundation phase.
- Prefer incremental optional-safety improvements where they don't alter behavior.

## Consolidation Skills

- For each flagged duplicate screen pair/group, confirm true-duplicate vs. device-variant status before deleting anything; document variants in code if kept.
- Only remove v1 DesignSystem tokens, unused pods, or dead code after confirming no remaining screen references them.
- Move specific, well-understood pieces of `Utils.m` into typed Swift services behind their existing protocol seam, one responsibility at a time, preserving exact behavior, with tests added before or alongside the move.

## Hardening Skills

- Prioritize test coverage gaps in this order: BLE command generation/parsing, DFU flow state, view model logic, then general utility code.
- Run a full hardware regression pass on BLE-critical flows before sign-off.
- Accessibility pass: VoiceOver labels, Dynamic Type at largest sizes, contrast in both light and dark mode, across all migrated screens.

## Architecture Checklist (verify per screen before calling it done)

- Screen has a view model; view controller contains no business logic or direct service/singleton access.
- Navigation for this screen goes through its flow's Coordinator.
- Legacy `Utils.m` / `.shared` access is isolated behind a foundation-phase service protocol.
- Connection UI (where relevant) is driven by a state enum, not independent booleans.
- Existing pushed/presented screens receive the same dependencies as before, via `AppDependencies`/coordinator, not a new singleton.
- Menu/destination definitions live outside the view controller.

## UI Review Checklist

- Screen fully uses DesignSystem v2 tokens — no leftover v1 tokens or hardcoded values.
- Text does not truncate unexpectedly on small devices.
- Tap targets are comfortably sized.
- Icons are consistently sized and aligned.
- Connection/status states are visually distinct.
- Card spacing and shadows look intentional, not heavy.
- Light and dark mode both maintain contrast.
- Animations are subtle and do not hide state changes.
- VoiceOver labels are present and accurate; Dynamic Type doesn't break layout at largest sizes.
