# UNDERDOG — initial balance notes

## Starting player
| Stat | Value |
|---|---:|
| Health | 100 |
| Stamina | 100 |
| Damage | 10 |
| Speed / dodge | 10% |
| Defence | 5 |

## Combat rules
- Dodge roll first; successful dodge means zero damage.
- Defence reduction follows: incoming × (1 - defence/100).
- Block then multiplies remaining damage by 0.32.
- Speed is capped at 60%.
- Heart activates at or below 25% health and adds a small critical chance.
- Rest restores 24 stamina and leaves the player open.
- Six turns form a round; three rounds per fight.

## Tournament opponent order

The eight-fight circuit uses one explicit roster shared by fight setup and hub preview:

| Fight | Opponent | Role |
|---:|---|---|
| 1 | Mick "The Meter" Doyle | Opening brawler |
| 2 | Glassjaw Gary | Opening speedster |
| 3 | Concrete Cal | Opening tank |
| 4 | Silk Moreno | Opening counter-puncher |
| 5 | Glassjaw Gary | Semi-final rematch, scaled up |
| 6 | Concrete Cal | Semi-final rematch, scaled up |
| 7 | Razor Venn | Title eliminator / dirty fighter |
| 8 | The Undertaker | Final champion |

Enemy health, stamina, damage, speed, and defence continue scaling with fight index, so rematches are intended to feel like tougher return bouts rather than fresh copies.

## Initial archetype strategies
- Glass cannon: stack damage, accept low defence, finish fights quickly.
- Evasive counterpuncher: prioritize speed and Counter/Slip, manage stamina.
- Durable pressure fighter: health, defence, Body Shot and efficient Jab.

## Risks to test
- Speed above 40% can become dominant; keep the 60% hard cap and consider diminishing returns.
- Rest spam can stall combat; enemy should punish resting through high-pressure patterns.
- High-damage move stacking can trivialize low-tier enemies; limit damage multipliers and maintain accuracy/cost trade-offs.
- Block every turn can create stalemates; stamina costs and enemy body shots should punish passive play.
- Heart should create a comeback, not a guaranteed win.
