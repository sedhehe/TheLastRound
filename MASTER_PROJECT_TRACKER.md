# UNDERDOG — Master Project Tracker

**Project:** UNDERDOG  
**Engine:** Godot 4.7  
**Genre:** First-person-presented, turn-based boxing roguelike  
**Tracker updated:** 25 November 2026  
**Repository:** https://github.com/sedhehe/UNDERDOG  
**Active branch:** `main`  
**Current priority:** Finish progression and tournament systems; defer visual/audio polish.

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

**Design note:** The current build uses 3 rounds of 6 turns per fight. The earlier broad brief said 3–5 rounds; the concrete current implementation and README specify 3. Treat changing this as a design decision, not an automatic cleanup.

---

## 2. Current overall status

**Current milestone:** Phase 3 — distinct enemy archetypes and tournament progression  
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
- Menu, hub, combat and Codex content now use a responsive vertical scroll container; the panel adapts to the viewport, follows keyboard focus and resets scroll on screen changes.
- The Codex has a top-level back action and a guide to enemy archetype mechanics.
- Enemy mechanics now differ: the brawler's Heavy Right hits harder; the speedster's landed attacks drain stamina; the tank's guard reduces incoming damage while it has stamina; the counter-puncher punishes committed attack moves; the dirty fighter drains stamina on a hit; and the final champion surges on turns 3 and 6.
- Enemy telegraphs, stamina/action handling, Heart, rounds and decisions are part of the current turn-based combat foundation.
- Corner Ice is reserved for between-fight use.
- Smelling Salts are intended to trigger automatically on a lethal hit, not through a manual item button.
- Combat inventory now exposes each usable item separately and consumes the selected item.
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
- [x] Improve move and item reward descriptions so choices communicate costs, accuracy, damage/effects and usage timing.
- [ ] Improve stat reward descriptions and trade-offs where needed.
- [ ] Finish regression coverage for move-slot overflow, duplicate upgrades, item capacity and every item effect.

**Status:** In progress. Reward clarity and item/effect summaries are implemented; manual regression remains open.

### Phase 3 — Tournament and roguelike loop

- [x] Eight-fight roster defined explicitly and used by fight setup and opponent preview.
- [x] Enemy stats scale with fight index.
- [x] Opponent progression has deliberate archetype/difficulty identities.
- [x] Hub/bracket preview identifies the next opponent.
- [x] Reward-to-next-fight transition requires reward resolution.
- [ ] Verify all eight fights as one uninterrupted run after the recent progression changes.
- [x] Implement distinct turn-based mechanics for the brawler, speedster, tank, counter-puncher, dirty fighter and final champion.
- [ ] Validate each archetype's special mechanic and tell in Godot.
- [ ] Complete defeat/full-run reset and run-summary edge-case coverage.
- [ ] Expand Respect meta-progression and unlock paths.
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

### Phase 4 — Functional UI and persistence

- [x] Basic combat HUD and move selection UI.
- [x] Enemy telegraph is surfaced in combat UI.
- [x] Combat log/action feedback foundation.
- [x] Hub/bracket and locker-room reward flow foundation.
- [x] Save and continue foundation; user-confirmed Phase 1 save/continue check.
- [x] Make menu, hub, combat and Codex content vertically scrollable with responsive panel sizing.
- [x] Add visible Codex back navigation and reset scroll position between screens.
- [ ] Main menu and pause-menu completeness.
- [ ] Full tournament bracket presentation.
- [x] Add enemy archetype explanations to the Codex.
- [ ] Complete Codex entries for items, rewards and tournament rules.
- [ ] Settings/accessibility completeness.
- [ ] Interactive tutorial.
- [ ] Clear item/effect and reward information in the UI.

**Status:** Partial. Existing functional UI should be extended rather than replaced wholesale.

### Phase 5 — Core testing and balancing

- [x] Phase 1 manual QA checks recorded as passed based on user confirmation.
- [ ] Batch regression test of all recent Phase 2 item/reward changes.
- [ ] Test a complete eight-fight run after current progression changes.
- [ ] Test every move and item.
- [ ] Test KO, knockdown and decision outcomes, including judge tie-breaks.
- [ ] Test save/load and run reset edge cases.
- [ ] Balance enemy scaling and rewards.
- [ ] Test multiple viable builds.
- [ ] Add deterministic seed replay.
- [ ] Run a 10,000-run balance simulation.
- [ ] Test save-file corruption recovery.
- [ ] Fix core gameplay bugs found during batch QA.

**Status:** In progress. Avoid stopping development for a manual test after every small commit; batch tests at meaningful milestones.

### Phase 6 — Visual presentation

**Deferred until core gameplay and progression are complete.**

- [ ] Fix first-person camera framing.
- [ ] Improve opponent models.
- [ ] Add punch, block and hit-reaction animations.
- [ ] Improve arena lighting.
- [ ] Add crowd and environmental details.
- [ ] Add camera shake and impact feedback.
- [ ] Add CRT, grain and dithering effects.

### Phase 7 — Audio and final polish

**Deferred until core gameplay is complete.**

- [ ] Punch and impact sounds.
- [ ] Crowd ambience.
- [ ] Bell and round transitions.
- [ ] Heartbeat at low health.
- [ ] Background soundtrack.
- [ ] Final balancing and performance.
- [ ] Build and release testing.

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

**Milestone: Make progression choices readable and reliable.**

1. Expand the Codex with item, reward and tournament explanations.
2. Review scouting previews so they explain tactical threats and counterplay.
3. Continue building Respect meta-progression and run-to-run unlocks without undermining the roguelike reset.
4. At the next milestone, batch-test scroll navigation, all archetypes, progression and one complete eight-fight run.

Do not begin visual/audio polish yet.

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
**Current phase:** Phase 2 — Progression  
**Next milestone:** Expand tournament strategy and finish Phase 2/3 regression at a grouped checkpoint  
**Visual/audio polish:** Deferred
