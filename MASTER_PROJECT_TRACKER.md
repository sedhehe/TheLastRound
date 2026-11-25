# The Last Round — Master Project Tracker

**Project:** The Last Round  
**Engine:** Godot 4.7  
**Genre:** First-person-presented, turn-based boxing roguelike  
**Tracker updated:** 25 November 2026  
**Repository:** https://github.com/sedhehe/TheLastRound  
**Active branch:** `main`  
**Current priority:** UI redesign, followed by graphics, animations, then grouped testing and balancing — in that order.

---

## 1. Original vision — design decisions

- First-person underground boxing tournament.
- 8 fights per run: 4 opening fights, 2 semi-finals, 1 title eliminator, 1 final boss.
- Each fight: 3 rounds, 6 player turns per round (current implemented design).
- Turn-based combat, not real-time action combat.
- Losing ends the run; winning progresses the tournament.
- Moves are earned through rewards.
- Starting moves: Jab, Block, Rest.
- Starting move slots: 4; maximum: 6.
- Health, stamina and speed are the core stats.
- At or below 25% health, the Heart comeback mechanic activates.
- Enemy archetypes: slugger/brawler, counter-puncher, dirty fighter, speedster and tank.
- Enemies telegraph their next attacks.
- Rewards, items, move upgrades and stat upgrades shape each run.
- Respect provides meta-progression between runs.
- Lifetime Respect persists across runs and determines a career rank: Unknown Fighter, Local Prospect (50), Known Contender (200), Circuit Headliner (500), Underground Legend (1000).

**Design note:** The current build uses 3 rounds of 6 turns per fight. The earlier broad brief said 3–5 rounds; the concrete current implementation and README specify 3. Treat changing this as a design decision, not an automatic cleanup.

---

## 2. Current overall status

**Current milestone:** Phase 4 — The Last Round branding updated; UI redesign next  
**Architecture correction:** Complete  
**Phase 1 core combat:** Implemented and user-confirmed in Godot  
**Phase 2 progression:** Partially implemented; remaining UI and regression work  
**Phase 3 tournament loop:** Eight-fight roster and scaling progression implemented; full-run validation remains part of batch QA  
**Phase 4 UI/persistence:** Basic combat, hub/reward UI, save/continue and Respect systems exist; several planned screens/features remain  
**Phase 5 QA/balancing:** In progress; do not treat the checked Phase 1 confirmation as proof that every new Phase 2 change has been tested  
**Phases 6–7:** Deferred

### What has actually changed since the original tracker

- Turn-based combat was restored as the active combat flow; the real-time combat path is not the intended gameplay loop.
- The user confirmed Phase 1 was working and asked development to continue.
- The user has now tested the three independent save slots in Godot and confirmed they work correctly.
- The user has tested the playable coach tutorial. They requested that an incorrect lesson move retry the same exchange rather than advance, and that the tutorial explain every item and how/when to use it.
- Menu, hub, combat and Codex content now use a responsive vertical scroll container; the panel adapts to the viewport, follows keyboard focus and resets scroll on screen changes.
- Fighter Training now launches a six-exchange playable spar against a coach, matching one complete six-turn round. Scripted tells teach reading a heavy right, body shot, quick jab and recovery window; contextual corner feedback explains the player's choices. The practice loadout exposes core attack, defence, counter and utility moves. Training is isolated from run progression, Respect and save data.
- Following the user's playtest, incorrect coach-drill choices now leave the same exchange and telegraph active and show corrective guidance; only an accepted response advances the exchange. The post-spar Corner Bag lesson explains all eight items, their exact effects and timing, how combat item buttons work, the opponent response/turn cost, hub-only Ice, automatic Smelling Salts and the three-item capacity.
- Run checkpoints write through a temporary file before promotion. The save system now has three independent run slots, each with its own checkpoint, temporary file, backup and corruption quarantine. Each slot can be continued independently or explicitly replaced after confirmation. Career Respect remains global across all three slots.
- The Codex has a top-level back action and a guide to enemy archetype mechanics.
- Enemy mechanics now differ: the brawler's Heavy Right hits harder; the speedster's landed attacks drain stamina; the tank's guard reduces incoming damage while it has stamina; the counter-puncher punishes committed attack moves; the dirty fighter drains stamina on a hit; and the final champion surges on turns 3 and 6.
- Enemy telegraphs, stamina/action handling, Heart, rounds and decisions are part of the current turn-based combat foundation.
- Corner Ice is reserved for between-fight use.
- Smelling Salts are intended to trigger automatically on a lethal hit, not through a manual item button.
- Combat inventory now exposes each usable item separately and consumes the selected item.
- Smelling Salts now always show one of three explicit states in combat, the hub and the reward screen: READY (owned), SPENT (revive used), or NOT IN YOUR BAG (not owned). The NOT IN YOUR BAG message explains that Salts come from an item reward.
- The corner bag shows its current slot count, item acquisition logs use full item names, and duplicate/after-use Smelling Salts are excluded from future item rewards.
- Career Respect now grants cumulative permanent starting perks on fresh runs: 50 Respect = +5 max HP (Grit), 200 = +5 max stamina (Conditioning), 500 = +1 damage (Power), and 1000 = +1 defence (Guard). Continue loads the saved fighter without reapplying perks.
- Run completion is guarded against duplicate end calls so a single run cannot award lifetime Respect twice.
- The Codex now includes item timing/effects and tournament rules, including reward resolution, between-fight recovery, run defeat and decisions.
- Career Respect is now loaded from the persistent meta save, displayed on the main menu and run summary, and converted into a lifetime rank. It remains separate from the current run's Respect.
- When move slots are full, move rewards are restricted to upgrades for already-owned moves.
- Reward resolution is required before advancing to the next fight.
- One explicit eight-fight roster is shared by opponent selection and the hub preview.
- Phase 1 QA checks are marked complete in `QA_CHECKLIST.md` based on the user's confirmation. New Phase 2 regression checks remain open.

**Verification boundary:** The user confirmed Phase 1 was good. Later GitHub changes are committed implementation, not claims of fresh Godot runtime verification. The assistant has not independently run the Godot project.

---

## 3. Phase-by-phase tracker

Legend:
- **Complete / confirmed** = implemented and the user confirmed the relevant Phase 1 behavior.
- **Implemented** = code is present, but the newest change still needs regression coverage.
- **Partial / pending** = some foundation exists, but the full feature is not complete.
- **Deferred** = intentionally not started yet.

### Phase 1 — Core combat

- [x] Restore turn-based combat architecture as the active combat flow.
- [x] Implement player action selection.
- [x] Implement Jab, Block and Rest.
- [x] Implement stamina costs and recovery.
- [x] Implement enemy attack selection.
- [x] Implement enemy telegraphs.
- [x] Implement dodge → block → damage resolution.
- [x] Implement Heart mechanic.
- [x] Implement KO and fight-end conditions.
- [x] Implement rounds and points decisions.
- [x] Complete a fight from start to finish.

**Status:** Complete; user confirmed Phase 1 was good. See `QA_CHECKLIST.md` for the recorded manual checks.

### Phase 2 — Progression

- [x] Data-driven move pool exists.
- [x] Implement move unlocking through rewards.
- [x] Implement move levelling/upgrades foundation.
- [x] Implement move-slot capacity and slot upgrades foundation.
- [x] Implement reward generation and three-choice reward flow.
- [x] Implement stat upgrades and trade-offs foundation.
- [x] Implement limited-use item effects.
- [x] Implement item capacity/effect handling foundation.
- [x] Prevent unusable new-move rewards when the loadout is full; offer owned-move upgrades instead.
- [x] Require reward selection before tournament advancement.
- [x] Expose each manually usable combat item with its own button; consume the selected item.
- [x] Keep Ice and Smelling Salts out of manual combat-use actions.
- [x] Add a clear item/effect summary to hub and combat UI.
- [x] Show Smelling Salts as READY, SPENT or NOT IN YOUR BAG across combat, hub and reward screens.
- [x] Prevent duplicate Smelling Salts rewards while owned or after the revive has been spent.
- [x] Show current corner-bag capacity and full item names when acquired.
- [x] Expand Codex with item definitions, usage timing and tournament rules.
- [x] Improve move and item reward descriptions so choices communicate costs, accuracy, damage/effects and usage timing.
- [ ] Improve stat reward descriptions and trade-offs where needed.
- [ ] Finish regression coverage for move-slot overflow, duplicate upgrades, item capacity and every item effect.

**Status:** In progress. Reward clarity and item/effect summaries are implemented; manual regression remains open.

### Phase 3 — Tournament and roguelike loop

- [x] Eight-fight roster defined explicitly and used by fight setup and opponent preview.
- [x] Enemy stats scale with fight index.
- [x] Opponent progression has deliberate archetype/difficulty identities.
- [x] Hub/bracket preview identifies the next opponent.
- [x] Hub scouting report shows the next opponent's archetype, tell and tactical counterplay.
- [x] Reward-to-next-fight transition requires reward resolution.
- [ ] Verify all eight fights as one uninterrupted run after the recent progression changes.
- [x] Implement distinct turn-based mechanics for the brawler, speedster, tank, counter-puncher, dirty fighter and final champion.
- [ ] Validate each archetype's special mechanic and tell in Godot.
- [x] Guard run completion against duplicate end calls and duplicate lifetime Respect awards.
- [ ] Complete defeat/full-run reset and run-summary edge-case coverage.
- [x] Persist lifetime Respect separately from run Respect and display career rank thresholds.
- [x] Add cumulative permanent career perks at 50/200/500/1000 Respect; apply them only when starting a fresh run.
- [ ] Expand Respect meta-progression into further unlockable options beyond the four starting-stat perks.
- [ ] Ensure scouting previews communicate useful tactical information, not only opponent names.

**Current roster:**

| Fight | Opponent | Intended role |
|---:|---|---|
| 1 | Mick “The Meter” Doyle | Opening brawler |
| 2 | Glassjaw Gary | Opening speedster |
| 3 | Concrete Cal | Opening tank |
| 4 | Silk Moreno | Opening counter-puncher |
| 5 | Glassjaw Gary | Scaled semi-final rematch |
| 6 | Concrete Cal | Scaled semi-final rematch |
| 7 | Razor Venn | Title eliminator / dirty fighter |
| 8 | The Undertaker | Final champion |

The roster is a deliberate current implementation. Rematches scale with fight index. If the user wants a different tournament structure, revise the roster as a design change.

### Phase 4 — UI redesign and persistence

- [x] Basic combat HUD and move selection UI.
- [x] Enemy telegraph is surfaced in combat UI.
- [x] Combat log/action feedback foundation.
- [x] Hub/bracket and locker-room reward flow foundation.
- [x] Save and continue foundation; user-confirmed Phase 1 save/continue check.
- [x] Make menu, hub, combat and Codex content vertically scrollable with responsive panel sizing.
- [x] Add visible Codex back navigation and reset scroll position between screens.
- [x] Show lifetime Respect and career rank on the main menu and run summary.
- [ ] Redesign the main menu and establish the visual design system.
- [ ] Redesign the hub/bracket and locker-room flow.
- [ ] Redesign the combat HUD, move selection and combat feedback.
- [ ] Redesign reward selection, run summary, Codex, settings and coach spar.
- [ ] Complete main menu and pause/navigation flow.
- [x] Add a full eight-fight tournament bracket to the hub, showing cleared, next and locked bouts.
- [x] Add enemy archetype explanations to the Codex.
- [x] Add Codex entries for all corner items and tournament rules.
- [x] Complete Codex entries for reward categories, move upgrades and current stat reward effects/trade-offs.
- [ ] Settings/accessibility completeness.
- [ ] Keep gameplay rules and state separate from presentation wherever practical.
- [x] Replace the text-only Fighter Training tutorial with a playable six-exchange coach spar using the turn-based combat flow.
- [x] Add scripted coach telegraphs and contextual feedback after player actions.
- [x] Keep practice runs isolated from tournament progression, Respect, rewards and save data.
- [x] User-tested the coach spar and its exit/restart/new-run transitions in Godot.
- [x] Add same-exchange retry feedback for incorrect tutorial moves.
- [x] Add a post-spar Corner Bag lesson covering all items and how/when to use them.
- [ ] Validate the new incorrect-move retry behavior and Corner Bag lesson in Godot.
- [ ] Clear item/effect and reward information in the UI.

**Status:** UI redesign is the next active phase. Existing gameplay systems and functional screens remain the foundation; redesign presentation without discarding working logic.

### Phase 5 — Graphics

**Begins after the UI redesign is implemented and its direction is approved.**

- [ ] First-person camera framing and player positioning.
- [ ] Arena environment, ring, ropes, crowd and underground venue details.
- [ ] Fighter and opponent model quality.
- [ ] Materials, textures and environmental props.
- [ ] Lighting direction, including the intended blue-toned arena ambience.
- [ ] CRT, grain, dithering and other image treatment where appropriate.

### Phase 6 — Animations

**Begins after the graphics pass establishes the final character and environment assets.**

- [ ] Player first-person punch animations.
- [ ] Opponent attack, guard, hit-reaction and recovery animations.
- [ ] Block, slip, clinch and knockdown animations.
- [ ] Round transitions, entrances and victory/defeat presentation.
- [ ] Camera movement, impact response and animation timing.
- [ ] Ensure animation playback remains synchronized with turn-based combat resolution.

### Phase 7 — Testing, balancing and release readiness

**Grouped testing follows the UI, graphics and animation passes, as requested. Implementation status is not a claim of runtime verification.**

- [x] Phase 1 manual QA checks recorded as passed based on user confirmation.
- [ ] Batch regression test of all Phase 2 item/reward changes.
- [ ] Test a complete eight-fight run.
- [ ] Test every move and item, including Smelling Salts when obtained.
- [ ] Test KO, knockdown and decision outcomes, including judge tie-breaks.
- [ ] Test save/load, overwrite, corruption recovery and run reset.
- [ ] Validate every enemy archetype's special mechanic and telegraph.
- [ ] Test the six-exchange coach spar and all exit/restart transitions.
- [ ] Balance enemy scaling, player progression and rewards.
- [ ] Test multiple viable builds.
- [ ] Add deterministic seed replay.
- [ ] Run a 10,000-run balance simulation.
- [ ] Run performance, compatibility and release-build checks.
- [ ] Fix gameplay, UI, graphics and animation bugs found during the grouped test pass.

**Status:** Planned after the UI, graphics and animation phases. Do not claim the game is tested until the grouped pass is actually completed.
---

## 4. Current implementation snapshot

Known project files include:
- `scripts/main.gd` — main game loop, tournament, rewards, inventory, save/meta-save and UI.
- `scripts/combat_manager.gd`
- `scripts/player_controller.gd`
- `scripts/player_combat.gd`
- `scripts/enemy_controller.gd`
- `scripts/arena_visuals.gd`
- `data/moves.json`
- `data/enemies.json`
- `data/items.json`
- `scenes/main.tscn`
- `QA_CHECKLIST.md`
- `BALANCE_NOTES.md`

The main turn-based combat loop currently lives in `main.gd`. Some older real-time controller/combat scripts remain in the repository; their presence does not mean real-time combat is the active design. Do not rewrite or delete them without checking current references first.

### Item behavior currently intended

- **Ice:** between-fight healing; not manually usable during combat.
- **Smelling Salts:** passive one-time revive on a lethal hit; not manually usable.
- **Other combat items:** individually accessible through their own combat buttons and consumed by exact item ID.

Recent inventory/reward fixes are committed, but the corresponding unchecked regression tests in `QA_CHECKLIST.md` remain open.

---

## 5. Immediate next milestone

**Milestone: Begin the UI redesign for The Last Round.**

The game is now branded The Last Round in its Godot project name, main menu, scene root, source comments/log prefix and project documentation. Legacy `underdog_*` run and career save files are intentionally deleted on the next game launch, as requested. New files use The Last Round naming; the three run slots are independent and Career Respect is shared across the game. The coach tutorial is a six-exchange playable spar. The next work sequence is fixed: UI redesign → graphics → animations → grouped testing and balancing. Existing runtime checks remain open until that final testing phase; Smelling Salts testing is not a development blocker.

1. Gather and translate the user's UI concepts into a consistent design system and screen layouts.
2. Implement the redesigned main menu, hub/bracket, combat HUD, rewards, run summary, Codex, settings and coach spar.
3. Move to graphics: arena, ring, crowd, fighters, materials and lighting.
4. Implement animations for the player, opponents, combat reactions and transitions; synchronize them with turn-based actions.
5. Run the grouped test and balancing phase only after the UI, graphics and animations are complete.
6. Fix issues found during that pass and prepare a release build.

Do not reorder the agreed production sequence: UI → graphics → animations → testing. Audio can be planned after the core presentation direction is established.

---

## 6. Development rules

1. Preserve the original design brief unless a change is explicitly approved.
2. Core gameplay comes before visual or audio polish.
3. Inspect actual source code before proposing code replacements.
4. Prefer complete replacement files or complete function replacements.
5. Never invent variable names, function signatures or project paths.
6. Explain exactly which file changed and how to pull/run it.
7. Do not claim something has been tested in Godot unless it actually has.
8. Update this tracker and `QA_CHECKLIST.md` when features, bugs or design decisions change.
9. Keep development moving; do not require manual testing after every small commit. Batch regression tests at milestone checkpoints.
10. Commit development changes directly to `main`, unless the user changes that instruction.
11. Inspect current repository state before editing; do not assume an earlier code snapshot is still current.

---

## 7. Pull latest changes

```bash
git checkout main
git pull origin main
```

Open the project in Godot 4.7 and run with F5. Stop the running game before pulling; the editor can usually remain open and reload the changed files. Use Project → Reload Current Project if the editor does not pick up changes.

**Tracker status:** Active  
**Current phase:** Phase 4 — UI redesign (combat HUD foundation committed)  
**Next milestone:** Persistent non-combat layouts, reward/hub panels and full UI asset review  
**Production order:** UI → graphics → animations → testing


### Three-slot save system — implemented, runtime QA pending

- [x] Replace the single run checkpoint with three independent slot files.
- [x] Give each slot its own temporary and backup files so writes cannot overwrite another slot.
- [x] Show all three slots on the main menu with EMPTY / checkpoint / damaged status.
- [x] Allow Continue to load only the selected slot.
- [x] Require explicit confirmation before starting a new run over an occupied slot.
- [x] Keep Career Respect global and shared across all three runs.
- [x] Remove the old `underdog_*` run and career save files on startup, as explicitly requested.
- [ ] In Godot, create and save three runs, then confirm each slot resumes its own fighter/build/fight progress.
- [ ] Confirm replacing one occupied slot leaves the other two unchanged.
- [ ] Confirm a completed/failed run clears only its own slot.
- [ ] Confirm malformed data in one slot is quarantined without affecting the other slots.
- [ ] Confirm the renamed career meta-save persists across all three slots and game restarts.


## 2026-11-25 — UI implementation started

**Committed directly to `main`:**
- Replaced the stacked text-only combat screen with a persistent full-viewport arena HUD.
- Added player and opponent health/stamina panels with live resource bars, a round/turn badge, a compact corner-talk panel, bottom move and item controls, a collapsible fighter/bag/stats drawer, and a forfeit action.
- Kept the underlying turn-based combat and reward logic authoritative. The combat HUD reads the existing dictionaries and move/inventory state; it does not introduce a parallel combat simulation.
- Added floating health-damage and stamina-change numbers anchored to the projected screen positions of the opponent and first-person player camera, including positive recovery feedback.
- Added a combat pause overlay toggled with Escape or the HUD button. It keeps the arena visible and blocks move/item input until resumed.
- Added hover tooltips for moves and items, plus a live active-effect summary in the fighter drawer.
- Unified non-combat menu buttons/panels with the same cold blue industrial palette as the arena HUD.
- Added opponent anticipation poses keyed to the selected telegraph (heavy/right, body/elbow, jab/flurry/combination, counter and reset/desperate swing). The forearms and gloves now move into different guard/load positions, with a separate attack follow-through and hit reaction.
- Wired the coach's scripted tells through the same anticipation-pose system.
- The non-combat menu panel remains the current presentation for menus, hub, rewards, Codex and settings; these are still to be redesigned into the visual system.

**Files changed:**
- `scripts/main.gd`
- `scripts/arena_visuals.gd`

**Important verification boundary:** These are source-level implementation commits only. Godot has not been launched in this environment; GDScript parsing, viewport behavior, button interaction, animation timing and resource-bar transitions remain unverified. Do not mark QA as passed until grouped runtime testing.

**Asset review limitation:** The 64 PNG assets in `UI/` are present in the repository, but the available GitHub file reader returns no usable image bytes for binary PNG files and the browser could not render the raw image. The filenames and inventory have been reviewed; the actual visual compositions have not. Do not claim pixel-level visual matching until the images can be viewed.

**Next implementation steps:**
1. Inspect/retrieve the PNG references in a viewable form without asking the user to re-upload the entire folder.
2. Continue the UI pass for title/menu, slot selection, hub/corner, reward choice, run end, tutorial, Codex and settings, preserving the existing mechanics and avoiding unnecessary full-screen transitions.
3. Refine combat HUD responsiveness, bar transitions, tooltips, active effects and touch/keyboard navigation.
4. Proceed to the planned graphics and fighter-animation passes only after the UI layouts are integrated.
5. Keep all runtime checks open for the final grouped test phase.


## 2026-11-25 — Non-visual gameplay reliability pass

- Fixed the Energy Drink crash path: the item already restored 35 stamina and marked a pending 10-stamina crash, but only the move-action path consumed that pending penalty. Using Energy Drink directly skipped the crash. The shared combat-item response path now applies the 10-stamina cost after the opponent's response, clears the pending flag, and records the stamina loss.
- This is a gameplay-logic correction only. No UI, arena, fighter-model or animation files were changed.
- Runtime verification remains pending; do not mark the related QA check passed until tested in Godot.


## 2026-11-25 — Reference review and combat controls/HUD pass

- Inspected the uploaded 12-page `UI_reference_review.pdf` and the original 64 PNGs in `New folder.zip`. The combat component rules, combat state review index, K01 preferences board, R25 controls, R26–R28 settings, all 22 combat states, run flow screens, and fighter pose references are now available as actual source images.
- Replaced the provisional combat HUD composition with the supplied 1600×900 reference hierarchy: player/opponent status across the top, centered round/turn counter, central phase banner, ringside commentary at right, three persistent corner-bag slots at bottom-left, six move slots at bottom-right, and the fighter drawer/pause affordances.
- The move row now reserves six stable positions. Keyboard move slots therefore remain stable as new moves are acquired.
- Corner bag now keeps all three slots visible. Q/W/E map to combat-usable items in bag order; Ice remains hub-only and Smelling Salts remain passive.
- Added R25 keyboard navigation: 1–6 moves, Q/W/E item slots, Tab fighter drawer, Esc pause/resume, F1 combat review index. Added a 22-card review index based on the combat state list; its scenario descriptions do not mutate the live fight.
- Enemy intent remains communicated through fighter animation/body language; the phase banner deliberately does not reveal the hidden move name.
- No changes were made to fighter geometry, arena lighting, crowd, or pose animation in this pass. Those are reserved for the visual-reference implementation pass.
- Runtime verification is pending; source edits are committed but have not been run in Godot 4.7.



## 2026-11-25 — Combat HUD reference-layout rebuild committed

- Replaced the previous panel-heavy combat HUD in `scripts/main.gd` with a reference-led, absolute-position composition based on the supplied 1600×900 combat screen.
- Removed the large opaque player/opponent status cards. The arena remains visible beneath a restrained translucent top status band; health and stamina bars, fighter stats and names sit directly on the HUD.
- Added the centered round/turn plate, compact phase strip, small right-side ringside commentary, three individual corner-bag slots at bottom-left, and six equal move cards at bottom-right.
- Preserved the existing combat callbacks and state: move selection, Q/W/E item use, Tab fighter drawer, Esc pause/resume, F1 review overlay, tooltips, selected-move state, and animated resource bars.
- Kept the existing pause, drawer and combat-review overlays rather than changing combat flow.
- Removed an unsupported Button wrapping-property assignment during source review.
- **Commits:** `fcdbd2e` (HUD rebuild), `8e58641` (Button property compatibility cleanup).
- **Verification boundary:** GitHub confirms both commits on `main`. Godot 4.7.2 has not been run here, so parsing, actual rendering, responsive scaling and interaction remain unverified. QA stays open until the grouped runtime pass.
