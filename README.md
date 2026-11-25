# The Last Round

A playable Godot 4 prototype for a first-person-presented, turn-based underground boxing roguelike.

## Requirements
- Godot Engine 4.3 or newer (4.x recommended)
- Windows, macOS or Linux

## Run
1. Download or extract the repository archive.
2. Open Godot Project Manager.
3. Click **Import**.
4. Select the folder's `project.godot` file.
5. Import and open the project.
6. Press **F5** to run the project.

The game opens at the main menu. Choose **NEW RUN**.

## Controls
The prototype is menu-driven:
- Select a move button to take your turn.
- Choose one reward after winning.
- Use the bracket/locker-room screen to prepare and enter the next fight.
- `Esc` is not currently bound to pause; use the UI navigation.

## What is included
- Procedurally built low-poly ring environment and crowd silhouettes.
- First-person camera facing a stylized opponent.
- Health, stamina, speed-based dodge, defence and Heart comeback mechanic.
- Starting moves: Jab, Block and Rest.
- Data-driven move, enemy and item definitions in JSON.
- Unlockable moves and a three-choice reward flow.
- Eight-fight run structure with escalating opponents and a final champion.
- Basic archetypes, enemy telegraphs, items, dirty-move disqualification risk.
- Run save/continue and Respect meta-save with permanent career perks at 50/200/500/1000 Respect.
- Codex and basic visual settings.

## Prototype limitations
This is a functional gameplay foundation, not a finished commercial release. The current build uses procedural primitive models and a compact UI. It does not yet include bespoke boxer animations, full controller remapping, production audio, comprehensive meta-unlocks, or a polished CRT post-processing shader. Fighter Training now includes a playable coach spar; its pacing and feedback still need in-engine validation. Some item definitions are included as data before all have dedicated acquisition routes. These are suitable next development tasks.

## Design defaults
- Eight fights per run.
- Three rounds per fight, six player turns per round.
- A round break restores stamina.
- If no knockout occurs after three rounds, remaining health determines the decision.
- Starting moves: Jab, Block, Rest.
- Move limit starts at four (the initial three moves leave one open slot).
- Speed dodge is capped at 60%.

## Project structure
- `scripts/main.gd`: prototype game loop, procedural arena and UI.
- `data/moves.json`: move definitions.
- `data/enemies.json`: enemy archetypes and stats.
- `data/items.json`: special item definitions.
- `scenes/main.tscn`: entry scene.

## Important
The project is designed to be extended. Before a public release, run it in your installed Godot version, test all combat paths, and expand the automated QA and balancing suite.
