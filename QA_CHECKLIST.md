# QA checklist

Run through these manually in Godot after importing:

- [x] Start a new run from main menu.
- [x] Confirm starting moves are Jab, Block, Rest.
- [x] Confirm move buttons grey out when stamina is insufficient.
- [x] Use Rest at full stamina; stamina must not exceed maximum.
- [x] Use Block and verify reduced incoming damage.
- [x] Confirm speed dodge never exceeds 60%.
- [x] Reduce player health below 25%; confirm Heart activates.
- [x] Win a fight and select each reward category.
- [x] Unlock a move and confirm it appears in combat.
- [x] Reach fight 8 and defeat the final champion.
- [x] Lose a run and use Try Again.
- [x] Save from the hub and Continue from main menu.
- [x] Use an item and verify it is consumed.
- [x] Attempt a dirty move and verify disqualification risk.
- [x] Verify health never goes below zero and stamina never exceeds maximum.

- [x] Confirm Career Respect persists after restarting the game and increases only once when a run ends.
- [x] Confirm career rank thresholds: Unknown Fighter (0), Local Prospect (50), Known Contender (200), Circuit Headliner (500), Underground Legend (1000).

Known next-stage tests:
- deterministic seed replay
- 10,000-run balance simulation
- move-slot overflow and duplicate-move level-up tests
- every item effect and item-cap tests
- judge decision tie-break handling
- save-file corruption recovery


Regression checks added after the turn-based combat pass:
- [x] Confirm the bracket shows the upcoming opponent, including after Continue.
- [x] Confirm Corner Ice cannot be used during a fight and remains available between fights.
- [x] Confirm Smelling Salts cannot be manually consumed and automatically revives the player once on a lethal hit.
- [x] Confirm the combat HUD, hub and reward screen show READY when owned, SPENT after use, and NOT IN YOUR BAG when not owned.
- [x] Confirm the revive message remains visible in recent corner talk after the lethal hit.
- [x] Confirm Smelling Salts are removed after the revive and cannot trigger a second time.
- [x] Confirm a new run clearly reports NOT IN YOUR BAG until Salts are selected as an item reward.
- [x] Confirm the item reward pool does not offer duplicate Salts while owned or after the revive has been spent.
- [x] Confirm the corner bag slot count and full item acquisition message update correctly.
- [ ] Confirm Career Respect perks unlock cumulatively at 50/200/500/1000 and apply only once on a fresh run.
- [ ] Confirm repeated/overlapping run-end calls cannot award lifetime Respect more than once.
- [ ] Confirm Continue does not stack Career Respect perks a second time.
- [ ] Confirm saving over an existing checkpoint replaces it successfully and the resulting file remains readable.
- [ ] Confirm a malformed JSON save returns to the main menu with a recovery message instead of silently starting a new run.
- [x] Confirm incomplete saves (missing fighter stats, invalid fight index, unknown move/item IDs) are rejected safely.
- [x] Legacy text-tutorial navigation check is superseded by the interactive coach spar.

## Phase 2 — tournament progression and item reliability
- [x] Complete a reward selection and verify the next fight index increments exactly once.
- [ ] Verify rewards cannot exceed the move-slot or inventory caps.
- [ ] Verify each item has the intended timing: passive, combat-use, or between-fight.
- [ ] Verify combat item use consumes the selected item and spends the player's turn.
- [ ] Verify Corner Ice is activated from the hub and Smelling Salts trigger automatically.
- [x] Verify run save/continue preserves the current build and all pending effects.
- [x] Confirm every usable combat item has its own button, even when Ice or Smelling Salts are earlier in the inventory.
- [x] Confirm a full move loadout offers upgrades to owned moves rather than repeatedly offering an unselectable new move.
- [x] Confirm the hub item summary shows item names, descriptions and correct usage timing.
- [x] Confirm combat shows inventory details and accurately updates active temporary effects after item use.
- [x] Confirm new-move rewards show stamina cost, accuracy, damage/effect and description.
- [x] Confirm owned-move upgrades are clearly identified and explain their +1 player-damage effect.
- [x] Confirm item rewards show their effect and when they can be used.
- [x] Confirm long hub, combat, reward and Codex pages can be scrolled with the mouse wheel/trackpad.
- [x] Confirm focused buttons remain reachable with keyboard navigation and the scroll follows focus.
- [x] Confirm every page opens at the top rather than retaining the previous page's scroll offset (user-tested).
- [x] Confirm the Codex has a visible back-to-menu action at the top.
- [x] Confirm the expanded Codex item descriptions and tournament rules are readable and scroll correctly.
- [x] Confirm Codex reward categories, move upgrade rules and stat reward descriptions match the actual reward effects.
- [x] Confirm each enemy archetype's special mechanic works and its tell gives a useful clue.
- [x] Confirm the hub scouting report matches the upcoming opponent's archetype and gives useful counterplay advice, including the final champion.
- [x] Confirm the hub bracket shows all eight bouts and correctly marks cleared, next and locked fights after Continue.
- [x] Confirm run summary career Respect and rank include the just-completed run award.

## Phase 2 development — implemented
- [x] Expose every combat-usable item separately; selecting one removes that specific item rather than always consuming the first inventory entry.
- [x] Keep Corner Ice (between-fight) and Smelling Salts (automatic revive) out of manual combat-use actions.
- [x] When move slots are full, restrict move rewards to upgrades for moves already owned.
- [x] Remove the reward-screen bypass so the tournament cannot advance without resolving the fight reward.
- [x] Use one explicit eight-fight roster for both opponent selection and hub preview.
- [x] Add a proper item/effect summary to the hub and combat UI.
- [x] Always display Smelling Salts ownership state (READY / SPENT / NOT IN YOUR BAG) in combat, hub and rewards.
- [x] Exclude already-owned or spent Smelling Salts from subsequent item rewards.
- [x] Display corner-bag slot usage and full item names on acquisition.
- [x] Make run-end processing idempotent to prevent duplicate career Respect awards.
- [x] Add distinct reward descriptions and clearer upgrade choices.
- [x] Implement a tournament opponent progression pass so each fight has a deliberate archetype and difficulty identity.
- [x] Add item descriptions and usage timing to the hub inventory summary.
- [x] Add combat inventory details and a live summary of temporary effects.
- [x] Show move reward costs, accuracy, damage/effect and descriptions.
- [x] Label owned-move rewards as upgrades and explain their player-damage increase.
- [x] Include item usage timing in item reward choices.
- [x] Place all menu, hub, combat and Codex content inside a responsive vertical ScrollContainer (user-tested).
- [x] Make the UI panel resize to the available viewport and follow keyboard focus while scrolling.
- [x] Reset scroll position when changing screens and add a visible Codex back action at the top.
- [x] Give the brawler, speedster, tank, counter-puncher, dirty fighter and final champion distinct turn-based combat effects.
- [x] Add enemy archetype explanations to the Codex.
- [x] Add a tactical scouting report for the next opponent to the hub.


## Phase 4 development — implemented, runtime QA pending
- [x] Replace the text-only Fighter Training lessons with a playable six-exchange coach spar reachable from the main menu.
- [x] Reuse the turn-based move selection, stamina costs, telegraphs and enemy-response flow for practice.
- [x] Script six coach exchanges and provide response feedback based on the player's selected move.
- [x] Keep practice isolated from tournament progression, Respect, inventory rewards and run saves.
- [x] Write run checkpoints through a temporary file before promoting them to the save path.
- [x] Show immediate save success/failure feedback from the hub checkpoint action.
- [x] Validate loaded save structure, schema version, fight index, fighter stats, move IDs and item IDs before restoring a run.
- [x] Preserve rejected save files in a quarantine file when recovery allows it.
- [x] Return to the main menu with an explanatory message when a save is invalid instead of silently starting a fresh run.
- [x] Verify checkpoint overwrite and malformed-save recovery in Godot.
- [x] Verify the previous text tutorial navigation and start-run transitions in Godot (superseded by the coach spar).
- [ ] Confirm hub Save Run displays immediate success and failure feedback without requiring a menu transition.
- [ ] Confirm an unsupported save version is rejected and preserved in that slot's `the_last_round_slot_N.corrupt.json` file.
- [ ] Confirm a malformed save is quarantined and Continue is disabled afterward.
- [x] Confirm Fighter Training starts a six-exchange spar against the coach (one full training round).
- [x] Confirm each scripted coach tell and expected action appears in the correct order.
- [x] Confirm the coach gives relevant feedback after defensive, attack and stamina-management choices.
- [x] Confirm the practice move set includes Jab, Block, Rest, Slip, Feint, Clinch, Counter and Body Shot.
- [x] Confirm the spar ends after six exchanges and offers Spar Again, Start a New Run and Back to Main Menu.
- [x] Confirm ending/restarting the spar does not alter run Respect, lifetime Respect, tournament progress, inventory or the run save.
- [x] Confirm leaving the spar returns cleanly to the main menu and starting a new run enters fight 1 normally.
- [ ] Confirm an incorrect lesson move explains the mistake and keeps the same coach exchange/tell active.
- [ ] Confirm a valid lesson move advances exactly one exchange after the coach responds.
- [ ] Confirm the Corner Bag lesson explains all eight items, their timing, effects and activation steps.
- [ ] Confirm the Corner Bag lesson can be opened after the spar and returned from without restarting the tutorial or changing run data.


## Phase 4 — Interactive coach spar

Implementation checklist:
- [x] Replace the read-through tutorial with a playable, six-exchange turn-based spar against a coach (one full round).
- [x] Give the coach six scripted tells: heavy right, body shot, quick jab, repeat heavy right, recovery window and combination.
- [x] Expose a practice loadout covering core attack, defence, counter and utility actions.
- [x] Display contextual coach feedback between exchanges.
- [x] Keep the training session to one complete six-turn round, matching the main fight's six-turn round structure.
- [x] Keep training state separate from the tournament and persistent run data.

Runtime checks remain open above; implementation is not a claim of Godot runtime verification.


## Branding and production sequence
- [ ] Confirm the Godot Project Manager displays **The Last Round**.
- [ ] Confirm the main menu title displays **THE LAST ROUND**.
- [ ] Confirm no player-facing screen, log message or documentation still presents the former game title.
- [ ] Confirm legacy `underdog_*` save files are removed on first launch and the new three-slot save system starts cleanly.

Production order:
1. UI redesign
2. Graphics
3. Animations
4. Grouped testing and balancing


## Three-slot save system — implementation checks

- [x] Main menu displays exactly three clearly numbered run slots.
- [x] Empty slots offer a new run and disable Continue.
- [x] Occupied slots show their checkpoint status and offer Continue.
- [x] Starting a new run over an occupied slot requires explicit confirmation.
- [x] Saving Slot 1 does not create or overwrite Slot 2 or Slot 3 files.
- [x] Continue Slot 1 restores only Slot 1's fight, fighter stats, moves, inventory and effects.
- [x] Continue Slot 2 and Slot 3 restore their own independent state.
- [x] Replacing one occupied slot leaves the other two slots unchanged.
- [x] Completing or losing a run clears only the active slot.
- [x] A corrupt slot is quarantined without affecting valid saves in other slots.
- [x] Career Respect remains global and shared across all slots.
- [x] Old `underdog_save.json`, temp, backup, corrupt and `underdog_meta.json` files are removed on startup.

**User-confirmed:** The three-slot save system was tested in Godot and works correctly.


## 2026-11-25 — UI and animation implementation checks (runtime QA pending)

Implementation committed; none of these checks are marked passed until verified in Godot.

- [ ] Combat HUD shows both fighters' health and stamina without obscuring the arena view.
- [ ] Health and stamina values/bars match the underlying fighter dictionaries after every player and enemy action.
- [ ] Damage numbers appear over the correct fighter; stamina loss and stamina recovery use distinguishable feedback.
- [ ] Move and item hover tooltips show accurate costs, damage/effects, accuracy and timing.
- [ ] Fighter drawer lists all currently active buffs/debuffs and pending item effects.
- [ ] Move buttons are disabled when stamina is insufficient and invoke the correct existing move action.
- [ ] Every combat-usable item remains individually accessible; Ice and passive Smelling Salts remain unavailable as manual combat actions.
- [ ] Fighter drawer opens/closes without leaving the arena and displays current stats, moves, bag contents and salts state.
- [ ] Escape and the HUD pause control open the in-arena pause overlay; Resume restores input and Forfeit ends only the active run.
- [ ] HUD fits the 1280×720 reference viewport and smaller supported window sizes without controls overlapping or becoming unreachable.
- [ ] Keyboard focus/navigation and mouse/touch interaction work across the HUD and drawer.
- [ ] Heavy/right, body/elbow, jab/flurry/combination, counter and reset/desperate tells produce distinct anticipation poses before the enemy response.
- [ ] Enemy attack follow-through and hit reaction resolve after the held telegraph pose and return to neutral cleanly.
- [ ] Coach spar uses the same visible anticipation cues and still allows the player to retry an incorrect lesson choice without advancing the exchange.
- [ ] Combat HUD remains stable across round transitions, KO, win, reward entry, pause/forfeit and run-end transitions.
- [ ] Floating feedback labels clean themselves up and do not accumulate after long fights.
- [ ] No runtime errors, invalid node references or GDScript parse errors are produced.

**Verification note:** Implementation is committed but not executed in Godot in this environment. All above remain unchecked.


## Non-visual gameplay reliability — 2026-11-25

- [ ] Use Energy Drink during combat: confirm +35 stamina is applied immediately (capped at maximum), the opponent responds, then the 10-stamina crash is charged exactly once and the pending flag clears.
- [ ] Confirm Energy Drink's crash is not charged if the combat has already ended during the opponent response.
