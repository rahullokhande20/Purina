# Purina iOS App — Refactor & UI Modernization Plan

Prepared as an app-architecture / UI-UX / engineering plan for the full app, building on the pattern already started on the Home screen (`DesignSystem`, `HomeRouter`, `HomeConnectionState`, `BluetoothConnectionService`).

## Current State (audit)

- 82 Swift files (~16,000 LOC) + a legacy Objective-C core: `Utils.h`/`Utils.m` (139 KB, one file), used directly by 14 Swift files.
- 173 references to singletons / `.shared` globals across the app.
- ~350 force-unwraps and ~55 `try!`/`as!` sites — a real crash-robustness risk, concentrated outside Home.
- Storyboard-driven navigation mixed with programmatic UIKit; iOS 15.6 minimum deployment target.
- Near-duplicate screens that need auditing before consolidation: `ChannelsViewController` / `Channels2ViewController`, `LNDViewController` / `LND2ViewController` / `LND339ViewController`, `ScrollViewController` / `Scroll2ViewController`, plus `PPGOldViewController` alongside newer PPG code. All are currently referenced in the Xcode project — likely device/firmware-variant screens, not dead code, but they duplicate a lot of UI and BLE-handling logic that should be shared.
- CocoaPods: `DGCharts`, `MBProgressHUD`, `NordicDFU`, `DropDown`, `DBNumberedSlider`, `IQKeyboardManagerSwift`, `SnapKit`, plus a git-sourced `MRHexKeyboard`.
- `NordicTests` / `NordicUITests` targets exist but contain only Xcode's default boilerplate — no real coverage today.
- Home screen already has a `DesignSystem` (palette, typography, spacing, radius, shadow, motion, haptics), a router/factory, a `HomeConnectionState` enum, and a `BluetoothConnectionService` facade — this is the template the rest of the app should follow, evolved into the target architecture below.

## Decisions Locked In

- **Sequencing:** foundation layers first (architecture, services, design system v2), then a screen-by-screen sweep applying them.
- **Visual direction:** move to a refreshed, more distinctive DesignSystem v2 (not just extending the current native look), rolled out consistently app-wide.
- **Architecture:** formal MVVM + Coordinator app-wide, replacing the storyboard-routing / massive-view-controller pattern.
- **Legacy core (`Utils.m`) and testing:** wrap `Utils.m` behind small protocol-based services now (no internal rewrite yet, to protect BLE/device behavior), and add unit tests incrementally as each piece is extracted rather than in one dedicated push.

---

## Phase 0 — Design Direction & Technical Baseline (1 step, do first)

**Design direction proposal.** Before any wide rollout, produce 2–3 concrete DesignSystem v2 directions (palette, type scale, iconography, card/elevation language, motion) as a short visual proposal — e.g. mockups of the Home screen and one device screen in each direction — for approval. Once approved, this becomes the single source of truth all screens migrate to, replacing the current v1 tokens.

**Technical baseline.**
- Enable stricter build settings where safe (treat new warnings seriously; do not silently allow new force-unwraps).
- Stand up a lightweight dependency-injection point (a small `AppDependencies`/`AppContainer` struct) so services and coordinators can be constructed and swapped in tests.
- Confirm the Xcode project's actual file membership vs. the duplicate screens listed above, and tag each duplicate as "distinct device variant — keep" or "true duplicate — merge" before Phase 2 touches them.

Deliverable: approved DesignSystem v2 direction + dependency container skeleton + duplicate-screen audit notes.

---

## Phase 1 — Foundation Layer

This phase touches no screen UI yet; it builds the scaffolding every screen will plug into.

**1. Navigation: App Coordinator.**
Introduce a root `AppCoordinator` plus per-flow coordinators (Home, Device Connection, DFU, Data/Charts, Files/Logs, Settings). Coordinators own navigation decisions; view controllers stop constructing or pushing other view controllers directly. `HomeRouter` becomes the first coordinator, generalized into the pattern the rest of the app reuses.

**2. MVVM scaffolding.**
Define the app's `ViewModel` conventions using plain input/output closures (decided — no Combine, no third-party reactive framework, to keep the foundation dependency-free and directly testable on the iOS 15.6 floor) and a base pattern for binding a view model to a UIKit view controller. Every screen touched in Phase 2 gets a view model; view controllers become binding + layout only.

**3. Service layer over legacy state.**
Wrap `Utils.m` and the 173 singleton/`.shared` call sites behind small protocols, grouped by responsibility (e.g. `BLEConnectionServicing`, `BLECommandServicing`, `DeviceFileWriting`, `DeviceLoggingServicing`). Internals stay untouched initially — this is a seam, not a rewrite — but every new/touched call site goes through the protocol instead of the global, and each protocol gets a real unit test with a fake/mock implementation as it's extracted. This directly extends the `BluetoothConnectionService` facade already started for Home.

**4. DesignSystem v2.**
Implement the approved Phase 0 direction as the new `DesignSystem`: palette (light/dark), type scale (Dynamic Type–aware), spacing/radius/elevation, motion, haptics, and a small set of reusable primitives (button styles, status chips, cards, empty/error states, loading states). This supersedes v1 but stays additive until every screen has migrated.

**5. Shared component library.**
Extract the UI patterns repeated across `Channels`/`Channels2`, `LND`/`LND2`/`LND339`, `Scroll`/`Scroll2`, and the DFU flow — chart containers, dropdown pickers, action-button rows, connection-status headers, alerts — into one reusable set of final classes with `configure(...)` methods, per the existing Home convention. This is what makes the later duplicate-screen consolidation possible without behavior risk.

**6. Testing harness.**
Add real test scaffolding to `NordicTests`: fixtures/mocks for the new service protocols, a couple of reference tests for a Phase-1 service (e.g. BLE connection state transitions) to establish the pattern for all future extractions.

Deliverable: Coordinator + MVVM conventions in place, legacy state wrapped behind tested protocols, DesignSystem v2 and shared component library ready, no visible screen changes yet beyond Home.

---

## Phase 2 — Screen-by-Screen Migration

Apply the Phase 1 foundation to every screen, grouped by user flow so each group ships as a coherent, testable unit. Suggested order (adjust freely):

1. **Home** — migrate the existing Home implementation onto the formal Coordinator/MVVM pattern (it currently uses the precursor router/state-enum approach) and onto DesignSystem v2.
2. **Device connection & scanning** — `PeripheralScanner`, `ServicesViewController`, `StatusViewController`.
3. **DFU update flow** — `DFUStartViewController`, `DFUUpdateViewController`, `DFUFirmwareSizeSection`, `DFUUpdateProgressView`, `DFUDocumentPicker`. High BLE-behavior sensitivity — architecture/UI only, no packet/command changes.
4. **Device data screens** — `ChannelsViewController`/`Channels2ViewController`, `LNDViewController`/`LND2ViewController`/`LND339ViewController`, `RightPCBViewController`. Consolidate onto shared chart/control components from Phase 1; resolve the "variant vs. duplicate" question from the Phase 0 audit here.
5. **Charts & scrolling data views** — `ScrollViewController`/`Scroll2ViewController`, `Line2GraphViewController`, `ECG & PPG` screens, `PPGOldViewController`.
6. **Files, logs, and text views** — `FileSelectorViewController`, `TxtViewController`, `LoggerTableView`, `SystemLog`/`LogObserver`.
7. **Remaining utility screens** — `DetailsViewController`, `TestingViewController`, `WebViewController`.

For each screen: extract a view model, route it through its flow coordinator, replace legacy singleton access with the Phase 1 service protocols, apply DesignSystem v2 and shared components, remove force-unwraps introduced or touched along the way, add unit tests for the new view model and any extracted BLE-adjacent logic, then validate with an Xcode build and a manual pass against the existing UI-review checklist (tap targets, Dynamic Type, light/dark contrast, truncation, animation clarity).

---

## Phase 3 — Consolidation & Cleanup

- Merge or formally separate the duplicate screens identified in Phase 0/2 now that they share components — either delete the true duplicate or document why the variant exists (e.g. different firmware/hardware target) directly in code.
- Sweep for dead code, unused pods, and leftover v1 DesignSystem tokens once every screen is on v2.
- Begin decomposing `Utils.m` itself where Phase 1's service seams make it safe to do so — moving logic into typed Swift services behind the same protocols, still preserving packet/command/file-writing behavior exactly.

## Phase 4 — Hardening & Sign-off

- Fill remaining gaps in unit test coverage, prioritizing BLE command generation/parsing, DFU flow state, and view model logic.
- Full regression pass on physical hardware for BLE-critical flows (connection, DFU, live data screens) since this is not something unit tests can fully cover.
- Accessibility pass (VoiceOver labels, Dynamic Type at largest sizes, contrast) across all migrated screens.
- Final build/diagnostics pass and removal of any temporary compatibility shims from Phase 1.

---

## Working Agreements (carried over from `instructions.md`/`skills.md`, extended app-wide)

- Read existing files before editing; confirm project membership before treating anything as dead code.
- One focused change at a time; validate with Xcode diagnostics and a full build after each phase.
- No BLE packet parsing, command generation, or file-writing behavior changes during architecture/UI passes — those are explicitly out of scope unless called out.
- No force unwraps in new or touched code; prefer `private` access and small, descriptive methods.
- One canonical implementation for shared UI types — never duplicate `DesignSystem`, buttons, chips, cells, or alert helpers across files.

## Decided Since This Plan Was Written

- MVVM binding style: plain input/output closures, no Combine or third-party reactive framework (see `instructions.md`). Full workflow detail is in `skills.md`.

## Open Items Still Outstanding

- Any existing brand guidelines (logo, exact brand colors) the DesignSystem v2 proposal should respect, or is the palette fully open?
- Access to a physical BLE device for hardware validation during Phases 2–4, or should validation lean more heavily on simulated/mocked BLE for now?
