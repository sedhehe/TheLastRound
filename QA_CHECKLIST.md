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
- [ ] Reach fight 8 and defeat the final champion.
- [ ] Lose a run and use Try Again.
- [ ] Save from the hub and Continue from main menu.
- [ ] Use an item and verify it is consumed.
- [ ] Attempt a dirty move and verify disqualification risk.
- [ ] Verify health never goes below zero and stamina never exceeds maximum.

Known next-stage tests:
- deterministic seed replay
- 10,000-run balance simulation
- move-slot overflow and duplicate-move level-up tests
- every item effect and item-cap tests
- judge decision tie-break handling
- save-file corruption recovery
