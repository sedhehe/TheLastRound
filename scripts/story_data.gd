extends RefCounted

const FIGHTER_LORE := {
	"mick": {
		"title": "DOCKYARD ENFORCER",
		"bio": "Former union brawler who lost his pension to a crooked foreman and started fighting cellar bouts for coal money. Slow feet, concrete fists.",
		"walkout": "Keep your chin tucked, rook. The concrete hits harder than I do.",
		"mid_line": "That all you packed? Now you're waking me up!",
		"defeat_line": "Damn... kid hits like an iron cleat..."
	},
	"gary": {
		"title": "SUBWAY PICKPOCKET",
		"bio": "Slippery alley sprinter who bets his own bail money on Decision victories. Can't take a clean hook to the jaw, so he never stays in one spot.",
		"walkout": "Blink twice and I'm already behind your ear, heavy boots.",
		"mid_line": "Hey—watch the face! Syndicate pays extra if I stay pretty!",
		"defeat_line": "Lights went out... before the count..."
	},
	"louie": {
		"title": "RINGSIDE SHARK",
		"bio": "Lace-cutter and rib-breaker hired by cellar bookies to soften up rising prospects before Tier 2. Smells liniment and copper a mile away.",
		"walkout": "Coach Miller send another lamb down the pipe? Hope you packed gauze.",
		"mid_line": "See that red on your trunks? We're just getting started!",
		"defeat_line": "Tell the bookies... cover the spread..."
	},
	"cal": {
		"title": "THE FOUNDRY WALL",
		"bio": "Twenty years hauling slag at the steelworks left his forearms thick as bridge cables. Shells up behind a double-iron guard until younger fists break.",
		"walkout": "Swing till your knuckles split, kid. I've outlasted better.",
		"mid_line": "Still swinging? Let's see what happens when the steel bends back!",
		"defeat_line": "Good punch... took forty of 'em, didn't I?"
	},
	"silk": {
		"title": "VELVET COUNTER-MAN",
		"bio": "Ex-pro middleweight barred from sanctioned arenas after a sparring partner never woke up. Fights loose, smiling, waiting for you to overreach.",
		"walkout": "Lead with your pride, please. It makes my right cross effortless.",
		"mid_line": "Cute rhythm. Pity I read your shoulders three seconds ago.",
		"defeat_line": "Clean timing... alright, kid. Take the chalk."
	},
	"callahan": {
		"title": "THE PIT HOUND",
		"bio": "Bitten half his mouthguard clean through during the Winter Riot Tournament. Fights harder the deeper his own nose bleeds.",
		"walkout": "DON'T DANCE! Stand in the pocket and bleed with me!",
		"mid_line": "HAHA! THERE IT IS! NOW NOBODY WALKS OUT CLEAN!",
		"defeat_line": "Best scrap... all winter... don't lose upstairs..."
	},
	"santos": {
		"title": "NEON CROWD PLEASER",
		"bio": "Draws high-rollers down the iron stairs just to watch him mock bruised challengers under the bare bulbs. Dangerous ego, deadlier wind-up.",
		"walkout": "Two hundred wallets downstairs bought a ticket to watch you fold!",
		"mid_line": "Think you stole my spotlight?! Watch what a real showstopper throws!",
		"defeat_line": "No... turn off those lights..."
	},
	"kowalski": {
		"title": "THE SYNDICATE SLEDGE",
		"bio": "Silent heavy-weight debt collector who speaks only after the ten-count. Every punch feels like a crowbar wrapped in soaked leather.",
		"walkout": "Ledger says your corner owes twice the purse. Stay down early.",
		"mid_line": "Hard head. Won't matter after the next overhand.",
		"defeat_line": "...Ledger's cleared, champ. Walk past me."
	},
	"razor": {
		"title": "BACK-ALLEY FIXER",
		"bio": "Never met a referee he couldn't blind with ten dollars or an elbow he wouldn't tuck inside a clinch. Keeps dirty fighters honest.",
		"walkout": "Rules stop at the top of the stairs, pal. Watch your ribs.",
		"mid_line": "Little slip of the thumb, nobody saw nothing—right, ref?!",
		"defeat_line": "Cold... how'd you see the elbow coming..."
	},
	"undertaker": {
		"title": "REIGNING CELLAR KING",
		"bio": "Has held The Crown through nineteen straight defenses without once lowering his stool between rounds. Never shouts, never blinks, never forgives an empty gas tank.",
		"walkout": "Sixteen names came down those stairs before you. None answered Round Three.",
		"mid_line": "So you actually survived to deep water. Show me if you can breathe down here.",
		"defeat_line": "...Twenty fights. Finally... a real bell."
	},
	"reaper": {
		"title": "CHAMPION RIPPER",
		"bio": "Syndicate champion carved out of scarred scar tissue and razor timing. Turns every championship bout into a slow bleed in the dark.",
		"walkout": "No judges down here tonight. Just your pulse in the chalk dust.",
		"mid_line": "Love that look in your eyes when the cut opens wide!",
		"defeat_line": "Haha... clean work... The Pit is yours, butcher..."
	},
	"kurosawa": {
		"title": "CHAMPION TACTICIAN",
		"bio": "Undefeated former Olympic alternate who walked away from gold medals for underground perfection. Reads breath, balance, and fear like sheet music.",
		"walkout": "Seven victories brought you under this lamp. Let us measure what precision built.",
		"mid_line": "You broke my timing. Good — now I stop holding back the counter.",
		"defeat_line": "Impeccable read. The Crown rests in steady hands tonight."
	}
}

const STORY_CHAPTERS := [
	{"id": "prologue", "act": "PROLOGUE", "title": "THE IRON STAIRS", "desc": "Coach Miller tapes your wrists in the damp boiler cellar before the first bell."},
	{"id": "act2", "act": "ACT II (BOUT 4)", "title": "HOUSE ODDS", "desc": "Three rungs cleared — the Syndicate pulls the rookies and sends specialists."},
	{"id": "act3", "act": "ACT III (BOUT 6)", "title": "THE FIXER'S ENVELOPE", "desc": "An underground runner slides dirty money under your corner stool."},
	{"id": "finale", "act": "ACT IV (BOUT 8)", "title": "THE LAST ROUND", "desc": "Under the single smoking cage lamp, tonight's Champion waits across the canvas."},
	{"id": "epilogue", "act": "EPILOGUE", "title": "NEW CROWN IN THE SMOKE", "desc": "The tenth count echoes across the cellar. Who walks back up into the rain?"}
]


static func get_fighter_lore(fighter_id: String) -> Dictionary:
	return FIGHTER_LORE.get(fighter_id, {
		"title": "UNDERGROUND CONTENDER",
		"bio": "A hardened veteran climbing The Glass Pit for one more purse.",
		"walkout": "Touch gloves and keep your hands high.",
		"mid_line": "Still standing? Let's trade for real!",
		"defeat_line": "Clean shot... caught me cold..."
	})


static func hub_act_banner(fight_idx: int, opp_name: String, boss_name: String, style_id: String) -> Dictionary:
	var goal_tail := "clear the ledger"
	match style_id:
		"slugger": goal_tail = "buy back your family's dock lease"
		"counter_pro": goal_tail = "prove the commission wrong"
		"dirty_rat": goal_tail = "wipe the house debt clean"
		"wildcard": goal_tail = "make a name out of nothing"

	if fight_idx == 0:
		return {
			"eyebrow": "THE LAST ROUND  /  ACT I: THE CELLAR RUNGS",
			"sub": "Eight fights to %s. %s waits first; %s holds the Crown tonight." % [goal_tail, opp_name, boss_name]
		}
	if fight_idx < 3:
		return {
			"eyebrow": "THE LAST ROUND  /  ACT I: RISING IN THE SMOKE",
			"sub": "Coach Miller: \"Keep reading shoulders and save stamina — %s won't give free openings.\"" % opp_name
		}
	if fight_idx < 5:
		return {
			"eyebrow": "THE LAST ROUND  /  ACT II: HOUSE ODDS",
			"sub": "Coach Miller: \"Syndicate specialists start here. Beat %s smart and stack your traits.\"" % opp_name
		}
	if fight_idx < 7:
		return {
			"eyebrow": "THE LAST ROUND  /  ACT III: SYNDICATE PRESSURE",
			"sub": "Coach Miller: \"Only house enforcers left before %s. Check the Black Market before you step in.\"" % boss_name
		}
	return {
		"eyebrow": "THE LAST ROUND  /  ACT IV: THE CHAMPIONSHIP BELT",
		"sub": "Coach Miller: \"Tonight's Crown runs through %s. Leave nothing on the stool — it's the last round.\"" % boss_name
	}


static func get_cutscene(scene_id: String, ctx: Dictionary) -> Dictionary:
	var style_id := str(ctx.get("player_style", "slugger"))
	var opp_id := str(ctx.get("opp_id", "mick"))
	var opp_name := str(ctx.get("opp_name", "Mick 'The Meter' Doyle"))
	var opp_arch := str(ctx.get("opp_archetype", "Brawler"))
	var opp_lore := get_fighter_lore(opp_id)
	var boss_id := str(ctx.get("boss_id", "undertaker"))
	var boss_name := str(ctx.get("boss_name", "The Undertaker"))
	var boss_lore := get_fighter_lore(boss_id)
	var cash_val := int(ctx.get("cash", 30))
	var kos := int(ctx.get("knockouts", 0))
	var has_dirty := bool(ctx.get("has_dirty", false))

	match scene_id:
		"prologue":
			var style_line := "Coach snaps fresh gauze round your knuckles. \"Eight names on the slate, kid. Win tonight and buy back your brother's dockside deed before the bank auctions it.\""
			var you_title := "PIT SLUGGER"
			match style_id:
				"counter_pro":
					you_title = "EX-RANKED COUNTER PUNCHER"
					style_line = "\"The Boxing Commission revoked your purse upstairs over a bad night in July. Down here under the boiler pipes, pure timing still settles every debt.\""
				"dirty_rat":
					you_title = "DEBT-BOUND ALLEY GRIFTER"
					style_line = "\"You owe the house double what's rattled in your coat pocket. Win eight straight against their own wolves — or you never climb back up those stairs.\""
				"wildcard":
					you_title = "UNLISTED FIGHTER"
					style_line = "\"No ring record, mismatched gloves, stale tape from the cellar bin. Nobody upstairs even wrote your name in ink — let's make sure they remember it.\""
			return {
				"id": "prologue",
				"eyebrow": "ACT I // PROLOGUE — THE IRON STAIRS",
				"title": "WELCOME TO THE GLASS PIT",
				"beats": [
					{
						"speaker": "THE VOICE OF THE PIT",
						"role": "UNDERGROUND PROMOTER",
						"accent": "cyan",
						"cam": "establish",
						"pose": "idle",
						"light": Color(0.58, 0.84, 0.98),
						"sfx": "commentary_cue",
						"line": "Down three flights beneath the old boilerworks, no judges keep scorecards. Eight fights climb to tonight's Champion: %s." % boss_name
					},
					{
						"speaker": "COACH MILLER",
						"role": "YOUR CORNERMAN  //  " + you_title,
						"accent": "amber",
						"cam": "corner",
						"pose": "recovery",
						"light": Color(0.88, 0.68, 0.42),
						"sfx": "foot_shuffle",
						"line": style_line
					},
					{
						"speaker": opp_name.to_upper(),
						"role": "BOUT 01  //  " + opp_arch.to_upper(),
						"accent": "coral",
						"cam": "staredown",
						"pose": "heavy",
						"light": Color(0.76, 0.90, 1.0),
						"sfx": "heavy_breath",
						"line": "“%s”" % str(opp_lore.get("walkout", "Keep your guard tight."))
					},
					{
						"speaker": "COACH MILLER",
						"role": "FINAL WORD BEFORE THE BELL",
						"accent": "amber",
						"cam": "opponent_closeup",
						"pose": "guard",
						"light": Color(0.65, 0.88, 1.0),
						"sfx": "bell_round",
						"line": "Eyes on his shoulders, not his mouth. Build Adrenaline, crack openings with Feints, and touch gloves — your first round starts now."
					}
				]
			}

		"act2":
			var cash_remark := "Bookies are already hedging your $%d warchest upstairs." % cash_val if cash_val >= 80 else "Spend every dollar you bleed for in the Black Market — you'll need better tape soon."
			return {
				"id": "act2",
				"eyebrow": "ACT II // BOUT 04 — HOUSE ODDS",
				"title": "THE CHALKBOARD THINS",
				"beats": [
					{
						"speaker": "THE VOICE OF THE PIT",
						"role": "UNDERGROUND PROMOTER",
						"accent": "cyan",
						"cam": "establish",
						"pose": "idle",
						"light": Color(0.54, 0.82, 0.96),
						"sfx": "crowd_cheer",
						"line": "Three challengers swept off the apron already. Word drifts up to the VIP balcony — someone in the blue corner is tearing through house odds."
					},
					{
						"speaker": "COACH MILLER",
						"role": "CORNER BRIEFING",
						"accent": "amber",
						"cam": "corner",
						"pose": "guard",
						"light": Color(0.90, 0.70, 0.40),
						"sfx": "foot_shuffle",
						"line": "The green kids are gone, kid. From Bout 4 upward, the Syndicate pays specialists to dismantle your rhythm. " + cash_remark
					},
					{
						"speaker": opp_name.to_upper(),
						"role": "BOUT 04  //  " + opp_arch.to_upper(),
						"accent": "coral",
						"cam": "opponent_closeup",
						"pose": "taunt" if opp_id in ["silk", "callahan"] else "heavy",
						"light": Color(0.92, 0.42, 0.36),
						"sfx": "bell_round",
						"line": "“%s”" % str(opp_lore.get("walkout", "Show me what beat the undercard."))
					}
				]
			}

		"act3":
			var bribe_line := "Management checked your ledger — word says you're not afraid of fighting dirty. Take a fall in Round 2 against %s and walk away with twice your purse." % opp_name if has_dirty else "A silk envelope lands beside the spit bucket. \"The house appreciates %d clean knockouts. Don't embarrass tonight's enforcer or tomorrow's debts double.\"" % maxi(1, kos)
			return {
				"id": "act3",
				"eyebrow": "ACT III // BOUT 06 — SYNDICATE PRESSURE",
				"title": "THE FIXER'S ENVELOPE",
				"beats": [
					{
						"speaker": "SYNDICATE RUNNER",
						"role": "BACKROOM MESSENGER",
						"accent": "violet",
						"cam": "corner",
						"pose": "recovery",
						"light": Color(0.62, 0.48, 0.92),
						"sfx": "commentary_cue",
						"line": bribe_line
					},
					{
						"speaker": "COACH MILLER",
						"role": "CORNERMAN",
						"accent": "amber",
						"cam": "staredown",
						"pose": "guard",
						"light": Color(0.92, 0.62, 0.32),
						"sfx": "crowd_gasp",
						"line": "Twenty years ago I took an envelope just like that so my family could eat — and watched the Pit steal my name anyway. Tear it up. Make them pay in front of the whole room."
					},
					{
						"speaker": opp_name.to_upper(),
						"role": "TIER 3 ENFORCER  //  " + opp_arch.to_upper(),
						"accent": "coral",
						"cam": "opponent_closeup",
						"pose": "enrage" if opp_id == "santos" else "heavy",
						"light": Color(0.94, 0.34, 0.30),
						"sfx": "bell_round",
						"line": "“%s”" % str(opp_lore.get("walkout", "Time to collect."))
					}
				]
			}

		"finale":
			var champ_color := Color(0.92, 0.30, 0.28)
			var champ_pose := "enrage"
			var champ_intro := "Nineteen straight challengers laid out cold under this same bulb. Every fighter thinks their story ends different — until Round Three."
			if boss_id == "kurosawa":
				champ_color = Color(0.72, 0.88, 1.0)
				champ_pose = "guard"
				champ_intro = "Seven brawls cannot teach timing. Every wasted step you take in this ring already belongs to me."
			elif boss_id == "reaper":
				champ_color = Color(0.96, 0.24, 0.30)
				champ_pose = "taunt"
				champ_intro = "Smell the rust on the canvas? Half of it used to belong to Coach Miller's boys. Step under the lamp."
			else:
				champ_color = Color(0.96, 0.56, 0.24)
				champ_pose = "heavy"
			return {
				"id": "finale",
				"eyebrow": "ACT IV // FINALE — THE LAST ROUND",
				"title": "THE CROWN OF THE GLASS PIT",
				"beats": [
					{
						"speaker": "THE VOICE OF THE PIT",
						"role": "MAIN EVENT ANNOUNCER",
						"accent": "amber",
						"cam": "establish",
						"pose": "idle",
						"light": champ_color,
						"sfx": "crowd_cheer",
						"line": "Seven victories in one night of blood and cellar smoke. Bolt the iron gate shut — for the undisputed Crown of The Glass Pit!"
					},
					{
						"speaker": boss_name.to_upper(),
						"role": str(boss_lore.get("title", "FINAL CHAMPION")),
						"accent": "coral",
						"cam": "champion_loom",
						"pose": champ_pose,
						"light": champ_color,
						"sfx": "crowd_gasp",
						"line": "“%s”" % str(boss_lore.get("walkout", champ_intro))
					},
					{
						"speaker": boss_name.to_upper(),
						"role": "CHAMPIONSHIP PROMISE",
						"accent": "coral",
						"cam": "opponent_closeup",
						"pose": "enrage",
						"light": champ_color,
						"sfx": "heavy_breath",
						"line": "“%s”" % champ_intro
					},
					{
						"speaker": "COACH MILLER",
						"role": "ONE LAST ROUND",
						"accent": "amber",
						"cam": "staredown",
						"pose": "guard",
						"light": Color(0.96, 0.78, 0.42),
						"sfx": "bell_round",
						"line": "Everything I lost twenty years ago sits across that canvas. Protect your chin, trust your reads, and leave nothing on the stool. Touch gloves."
					}
				]
			}

		_:
			# Epilogue (Champion Defeated!)
			var style_ending := "Coach unwraps the soaked red tape from your hands. \"That deed stays in your family's name. Walk out into the rain with your head high.\""
			match style_id:
				"counter_pro":
					style_ending = "\"Let the commission print whatever story they want upstairs. Everyone inside these cellar walls saw real artistry win clean tonight.\""
				"dirty_rat":
					style_ending = "\"The bookie's ink hits zero tonight, and every shark on the balcony knows better than to chase your shadow up those stairs again.\""
				"wildcard":
					style_ending = "\"Walked in as nobody from nowhere. Walked out wearing every heavyweight's nightmares around your knuckles.\""
			return {
				"id": "epilogue",
				"eyebrow": "EPILOGUE // NEW CROWN IN THE SMOKE",
				"title": "LAST BELL IN THE GLASS PIT",
				"beats": [
					{
						"speaker": boss_name.to_upper(),
						"role": "FALLEN CHAMPION",
						"accent": "coral",
						"cam": "opponent_closeup",
						"pose": "slump",
						"light": Color(0.92, 0.38, 0.28),
						"sfx": "crit_ko",
						"line": "“%s”" % str(boss_lore.get("defeat_line", "...The Crown is yours."))
					},
					{
						"speaker": "THE VOICE OF THE PIT",
						"role": "RING ANNOUNCER",
						"accent": "mint",
						"cam": "victory_crown",
						"pose": "slump",
						"light": Color(0.98, 0.78, 0.34),
						"sfx": "win_champion",
						"line": "TEN! IT'S OVER! Eight straight in one night — %d knockouts and $%d in hard purse! A new undisputed King claims The Glass Pit!" % [maxi(1, kos), cash_val]
					},
					{
						"speaker": "COACH MILLER",
						"role": "YOUR CORNERMAN",
						"accent": "amber",
						"cam": "corner",
						"pose": "slump",
						"light": Color(0.54, 0.90, 0.78),
						"sfx": "crowd_cheer",
						"line": style_ending
					},
					{
						"speaker": "THE GLASS PIT",
						"role": "RUN COMPLETE",
						"accent": "cyan",
						"cam": "establish",
						"pose": "slump",
						"light": Color(0.68, 0.90, 1.0),
						"sfx": "bell_double",
						"line": "Every scar earned in the cellar stays carved on your record. Claim your Career Respect — and step back down whenever the Pit calls again."
					}
				]
			}
