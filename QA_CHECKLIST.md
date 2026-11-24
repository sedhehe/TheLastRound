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
- [ ] Confirm Smelling Salts cannot be manually consumed and automatically revives the player once on a lethal hit.
- [ ] Confirm the combat and hub UI clearly show Smelling Salts as READY before the revive and SPENT afterward.
- [ ] Confirm Smelling Salts are removed after the revive and cannot trigger a second time.

## Phase 2 — tournament progression and item reliability
- [x] Complete a reward selection and verify the next fight index increments exactly once.
- [ ] Verify rewards cannot exceed the move-slot or inventory caps.
- [ ] Verify each item has the intended timing: passive, combat-use, or between-fight.
- [x] Verify run save/continue preserves the current build and all pending effects.
- [ ] Confirm every usable combat item has its own button, even when Ice or Smelling Salts are earlier in the inventory.
- [x] Confirm a full move loadout offers upgrades to owned moves rather than repeatedly offering an unselectable new move.
- [x] Confirm the hub item summary shows item names, descriptions and correct usage timing.
- [x] Confirm combat shows inventory details and accurately updates active temporary effects after item use.
- [x] Confirm new-move rewards show stamina cost, accuracy, damage/effect and description.
- [x] Confirm owned-move upgrades are clearly identified and explain their +1 player-damage effect.
- [ ] Confirm item rewards show their effect and when they can be used.
- [x] Confirm long hub, combat, reward and Codex pages can be scrolled with the mouse wheel/trackpad.
- [x] Confirm focused buttons remain reachable with keyboard navigation and the scroll follows focus.
- [x] Confirm every page opens at the top rather than retaining the previous page's scroll offset (user-tested).
- [x] Confirm the Codex has a visible back-to-menu action at the top.
- [ ] Confirm the expanded Codex item descriptions and tournament rules are readable and scroll correctly.
- [x] Confirm each enemy archetype's special mechanic works and its tell gives a useful clue.
- [ ] Confirm the hub scouting report matches the upcoming opponent's archetype and gives useful counterplay advice, including the final champion.

## Phase 2 development — implemented
- [x] Expose every combat-usable item separately; selecting one removes that specific item rather than always consuming the first inventory entry.
- [x] Keep Corner Ice (between-fight) and Smelling Salts (automatic revive) out of manual combat-use actions.
- [x] When move slots are full, restrict move rewards to upgrades for moves already owned.
- [x] Remove the reward-screen bypass so the tournament cannot advance without resolving the fight reward.
- [x] Use one explicit eight-fight roster for both opponent selection and hub preview.
- [x] Add a proper item/effect summary to the hub and combat UI.
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
