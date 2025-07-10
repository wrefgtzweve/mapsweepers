--[[
	Map Sweepers - Co-op NPC Shooter Gamemode for Garry's Mod by "Octantis Addons" (consisting of MerekiDor & JonahSoldier)
    Copyright (C) 2025  MerekiDor

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

	See the full GNU GPL v3 in the LICENSE file.
	Contact E-Mail: merekidorian@gmail.com
--]]

jcms.bestiary = {}

-- // Antlion {{{

	jcms.bestiary.antlion_cyberguard = {
		faction = "antlion", bounty = 300, health = 450,
		mdl = "models/antlion_guard.mdl", mats = { "models/jcms/cyberguard" }, camlookvector = Vector(0, 0, 50),
		name = [=[CyberGuard]=], desc = [=[This is an upgraded Guard engineered by Mafia R&D *specifically* just to piss us off. They're still mostly organic inside. Their outer shell, however, has been largely replaced with intimidating-looking electronics and metal. They also have the ability to apply single-use spherical shields to nearby friendlies that will absorb any damage exactly once, no matter how weak or strong it is. Anyways, these beasts are (somehow) weaker than natural-born guards, but their plated skin further reduces harm from low-damage weapons. It is best to penetrate their armor with heavy, slow-firing weapons and explosives. Though, statistically, you fucking idiot sweepers stick to whatever fancy-looking fast-firing high-DPS bullshit guns you find in the multiverse. Therefore yes, simply shooting a CyberGuard should be enough to take it down anyway.]=]
	}

	jcms.bestiary.antlion_drone = {
		faction = "antlion", bounty = 15, health = 30,
		mdl = "models/antlion.mdl", camfov = 28,
		name = [=[Drone]=], desc = [=[A common antlion. This specific variant is a mindless drone that can't do basic math or work a desk job (though if we were to evacuate one of them to the mothership, we could easily give 'em a tie and a cubical). Some antlions can speak, some even act completely human - those will usually be idling around, staring off into space... Chances are, they're getting murdered by none other than you, though. Either way, if they happen to be transformed humans - y'know, one of those idiots signing up for the "Let's do crazy science shit and re-enact Kafka's The Metamorphosis" weekly letter - you shouldn't feel bad about killing them. In fact, you'll be doing them a favor, because this is the fastest way they'd respawn back home in a human body. Hopefully. Right, I got sidetracked. Okay, what about antlions? They fly and they swarm you. Just shoot them! High-firerate weapons are favored.]=]
	}

	jcms.bestiary.antlion_guard = {
		faction = "antlion", bounty = 350, health = 675,
		mdl = "models/antlion_guard.mdl", camlookvector = Vector(0, 0, 50),
		name = [=[Guard]=], desc = [=[We are not sure if they're the same species as the ordinary Antlion Drones... but what we do know, is that these brutes are plain merciless and unstoppable. They will easily destroy our turrets in a single shove, sending 'em flying away on fire. So that's bad news for the fans of automating their killings. Other than that, they're actually a bit weaker than they look. Try strapping a Timed Explosives on one of them, and it'll be gone in 10 seconds. Make sure you can outrun it, though. Otherwise, the bomb will take you with it.]=]
	}

	jcms.bestiary.antlion_reaper = {
		faction = "antlion", bounty = 75, health = 200,
		mdl = "models/antlion.mdl", mats = { "metal2" }, color = Color(195, 150, 38),
		name = [=[Reaper]=], desc = [=[It's a mystery whether these are cybernetic, organic or magical in nature. Mafia hasn't responded to our "what the FUCK is that" e-mails when we first saw them ourselves. Therefore, the information we can give you is limited. As wild as it sounds, "Reapers" are heavy, flightless antlions with floating orb-eyes that shoot sweeping laser beams... Some find them intimidating, others find them hilarious. Dodge the beams, and you'll be fine. We don't think they are capable of melee combat.]=]
	}

	jcms.bestiary.antlion_ultracyberguard = {
		faction = "antlion", bounty = 600, health = 563,
		mdl = "models/jcms/ultracyberguard.mdl", camlookvector = Vector(0, 0, 50),
		name = [=[ACLP-1]=], desc = [=[After designing the CyberGuard, Mafia took a step further and made a completely robotic version of a Guard. Though honestly, we still don't know what they call them. JonahSoldier, the CEO of J Corp, glanced at one, said "ultra-cyberguard" in an uninterested tone and went back to his business. We thought calling it an "ultra-cyberguard" wasn't instilling enough fear into the sweepers, so we gave it a cool acronym. It stands for "Antlion Cybernetic Laser Platform". Compared to a normal Guard, it's more agile and more aggressive, though it's pretty easy to kill. It also has a laser cannon for a head (which honestly seems to be all bark and no bite) where it gets the acronym from. Despite custom design and mass-production, Mafia doesn't seem to use ACLPs as a regular combat unit at all, likely due to their inefficiency. Which means, they designed this thing just to fuck with us, nothing else. Again. Seriously?]=]
	}

	jcms.bestiary.antlion_waster = {
		faction = "antlion", bounty = 5, health = 15,
		mdl = "models/antlion.mdl", scale = 0.63, color = Color(168, 125, 59), camfov = 28,
		name = [=[Waster Drone]=], desc = [=[Basically, this is a smaller & weaker Antlion Drone. No, they're not "young antlions" at all. In fact, these seem to be some sort of scrawny adults that are unable to breed due to their natural small size. This also makes them savagely fierce. They're easy to kill, but they're going to do everything just to getcha. Wasters are so full of hate that they probably would attack bigger antlions, too... But that doesn't seem to happen, though. Could they experience fear?]=]
	}

	jcms.bestiary.antlion_worker = {
		faction = "antlion", bounty = 50, health = 60,
		mdl = "models/antlion_worker.mdl", 
		name = [=[Worker]=], desc = [=[Evolution has endowed these bugs with an acid spit. Normally, when they aren't bent on killing you, they use it to dig tunnels. And, well, it needs no saying that it melts through metal armor of our tanks & turrets just as easily as it dissolves rocks. Workers are going to try and stay behind the lines to get your defenses out of order. Moreover, killing them makes them burst and coat everything nearby in acid, so watch out for that.]=]
	}

-- // }}}

-- // Combine {{{

	jcms.bestiary.combine_cybergunship = {
		faction = "combine", bounty = 700, health = 4500,
		mdl = "models/gunship.mdl", mats = { "", "models/jcms/cybergunship/body" }, scale = 0.3,
		name = [=[Strafer Gunship]=], desc = [=[Gunships that have been hyper-optimized for using their belly-cannon beam. They're overflowing with deadly blue energy. So no fucking around, soldier; you should know how bad the color blue is for business and J Corp as a whole. Their cannons have been upgraded to fire explosive rounds, and they will use their laser much more often than normal gunships. When you hear a siren, KEEP RUNNING! Strafer gunships don't just do a single run, they will keep going after you, so evading it once won't work.]=]
	}

	jcms.bestiary.combine_elite = {
		faction = "combine", bounty = 95, health = 80,
		mdl = "models/combine_super_soldier.mdl", camfov = 30,
		name = [=[Elite Soldier]=], desc = [=[An advanced Overwatch soldier, further enhanced by J Corp after we invaded and took full control of the entirety of Universal Union's overworld and subsidiary universes as a result of the "15-minute scuffle". We fitted these guys with a magnetic shield not unlike the one built into sweeper suits. The reason we favored these soldiers is because they have a cool red eye, and we love all things red. Anyway, point is, J Corp generates profit from your engagements with the Combine. We order the Combine to fight you, and we pay you to fight the Combine, which is one of our greatest and most lucrative business strategies. Elite Soldiers carry AR2s and can shoot dark energy balls that'll reposition your turrets in unexpected ways. We've also heard rumors about an SMG-wielding Elite on the loose, but rest assured, it's only rumors. Probably.]=]
	}

	jcms.bestiary.combine_gunship = {
		faction = "combine", bounty = 450, health = 4500,
		mdl = "models/gunship.mdl", scale = 0.3,
		name = [=[Gunship]=], desc = [=[Flying combat synths that look like repurposed space dolphins. They are quite aggressive and don't respond well to Turrets (which they consider to be crude mockery of their own image). That's why - you guessed it - Gunships will quickly leave you defenseless, even if their mouth-machinegun isn't directly dangerous on it's own. If you're lucky enough to be sweeping a map that features enterable buildings or underground sections, you can easily hide from a Gunship indoors. Otherwise, use Orbital Beams and Anti-Air Missiles to take them down before they can charge their devastating belly cannon. Right right right, their belly cannon... Gunships are capable of firing a powerful blue beam directly under themselves. Standing in it for longer than a second is a certain death. So when you see things get more blue than they usually are, you better take a few steps to the side.]=]
	}

	jcms.bestiary.combine_hunter = {
		faction = "combine", bounty = 125, health = 210,
		mdl = "models/hunter.mdl", 
		name = [=[Hunter]=], desc = [=[Also known as "ministriders", Hunters are sadistic little bastards designed to catch your attention. They have a built-in explosive flechette cannon, and can charge at you & knock you back with a body slam. However, despite their imposing appearance and vicious nature, they're rather easy to kill. Hunters are especially weak to explosives and blunt things bonking their heads, meaning Engineers wielding a Gravity Gun can kill a Hunter without firing a bullet: just fling a turret at it! (though, admittedly, it's faster just to shoot the Hunter to death)]=]
	}

	jcms.bestiary.combine_metrocop = {
		faction = "combine", bounty = 40, health = 40,
		mdl = "models/police.mdl", camfov = 30,
		name = [=[Metrocop]=], desc = [=[Cops who have been plucked from their city patrol duties just to try and kick your ass. Metrocops carry a manhack with them. Manhacks themselves are nothing dangerous, but they are two other things: a wasted bullet, and a reset shield regeneration. Most metrocops you see aren't very used to real combat. Their usual job is patrolling controlled territories of whichever faction pays the most (usually J Corp), standing next to explosive barrels and dropping environmental storytelling one-liners every once in a while. It's a dream job, right? So you can imagine how frustrated they are to suddenly get pulled into a portal and be instructed with: "Alright, deal some damage to this red-suit-wearing bunny-hopping motherfucker before you go down". Metrocops are pretty insomniac, too, so they just kinda shoot in your general direction and hope the manhacks do the rest. After you kill them, they respawn whereever they used to be, sigh, take their mask off, smoke, and continue their shift.]=]
	}

	jcms.bestiary.combine_scanner = {
		faction = "combine", bounty = 15, health = 30,
		mdl = "models/combine_scanner.mdl", camfov = 20,
		name = [=[Scanner]=], desc = [=[Flying little drones that relay information to their assigned squads. Once you're spotted by one, you can be sure that an Overwatch squad is coming your way. They are otherwise harmless, though they do distract turrets and will kamikaze into you upon being shot down. Scanners are annoying, if anything. Luckily, at least they don't seem to blind you with a bright flash.]=]
	}

	jcms.bestiary.combine_sniper = {
		faction = "combine", bounty = 75, health = 38,
		mdl = "models/combine_soldier_prisonguard.mdl", skin = 1, camfov = 30,
		name = [=[Sniper]=], desc = [=[Far-reaching, annoying prick with a perfectly accurate plasma sniper rifle. The bullets are conveniently slow enough for you to dodge, though. Move away as soon as you hear a gunshot. When their combine overworld teacher (or whoever the hell) asked them who they want to be when they grow up, they responded with "Eh, y'know, a total fucking dipshit". Snipers will be the reason you'll see your turrets gone, one-by-one. They will be the reason you can't just stand still and hack a terminal for a moment in peace. There is little honor to what they do.]=]
	}

	jcms.bestiary.combine_soldier = {
		faction = "combine", bounty = 70, health = 50,
		mdl = "models/combine_soldier.mdl", camfov = 30,
		name = [=[Soldier]=], desc = [=[The Combine has converted many volunteers into cybernetic soldiers, something something "overwatch transhuman arm" or whatever. Supposedly, these are the ultimate combatants: obedient, fearless, yada yada. Truth is, they're fodder, but deadly in numbers. They're capable of using various tactics (mostly flanking) to direct some sure damage your way. Combine Soldiers are armed with SMGs, AR2s and Shotguns, and carry a grenade which can be thrown back where it came from. Those with SMGs will attempt to flank you, those with AR2s will mostly stay put and shoot, and those with Shotguns will charge at you.]=]
	}

	jcms.bestiary.combine_suppressor = {
		faction = "combine", bounty = 130, health = 90,
		mdl = "models/combine_soldier_prisonguard.mdl", skin = 2, camfov = 30,
		name = [=[Suppressor]=], desc = [=[Combine Heavies wielding a powerful machinegun. A suppressor's primary role is in their name, they're tanky and dangerous, but slow. You'll almost never see them running and gunning at the same time, which is why they're an easy target to pick off. Nonetheless, when left unattended, one of these soldiers will personally drag you to hell with a volley of bullets. Or your turrets. Did I mention how quickly they shred your turrets? Well, you'll see.]=]
	}

-- // }}}

-- // Rebels {{{

	jcms.bestiary.rebel_alyx = {
		faction = "rebel", bounty = 75, health = 45,
		mdl = "models/alyx.mdl", camfov = 30, seq = 3,
		name = [=[Alyx Vance]=], desc = [=[This elusive woman may seem like a competent hacker, able to simply stare at our machines and take control of them, but the reality is much more grim. As a higher tier gambler, she has gambled so much that her veins simply flow with gamblium instead of blood. Her sheer touch is enough to infuse our turrets with enough purple to turn them into gamblers, too. Fortunately, your stunsticks are infused with J, which can cure gambling, so all you need to do is hit them with it and the "hacked" object will remember their J Corp mandated lessons on market shares, business suits, and red. She used to turn our sweepers into gamblers, too, but it seems she hasn't been gambling enough recently to successfully pull it off.]=]
	}

	jcms.bestiary.rebel_dog = {
		faction = "rebel", bounty = 135, health = 240,
		mdl = "models/dog.mdl",
		name = [=[D0G]=], desc = [=[This thing was born out of pure hatred for mechanical objects. It doesn't matter if it's house plumbing, complex telecommunication arrays, or your sentry nest - this thing will see it and feel HATRED. And then it'll run up to it, grab it even if it's goddamn bolted to the floor or wall, then throw it at the nearest thing that isn't purple (this can deal a lot of damage!), or bring them them to Alyx for her to hack, because though it hates all engineering, it also loves spreading the gambling. It's also heavy enough to ground-slam and launch everything into the air, so watch out for that. It seems to be in denial of it's own mechanical nature. Traeesen has asked us not to remind it of that, because it's going to therapy for that.]=]
	}

	jcms.bestiary.rebel_fighter = {
		faction = "rebel", bounty = 30, health = 45,
		mdl = "models/humans/group03/male_07.mdl", seq = 1, camfov = 30,
		name = [=[Fighter]=], desc = [=[Run-of-the-mill gambler. Their gear is a lot cheaper and more worn than that of our troops, because any profit they make, they gamble it away. Then they dare complain about their “poor quality of life”. This would be an advantage for you, but despite their poverty, they are surprisingly hard to kill. Maybe it’s their sheer stupidity that keeps them alive. We’ve tried many times to teach them about business, and investing, and stocks, it just doesn’t work. They tank it like they tank bullets. Do me a favor and show these environmentalists no mercy.]=]
	}

	jcms.bestiary.rebel_helicopter = {
		faction = "rebel", bounty = 400, health = 1764,
		mdl = "models/combine_helicopter.mdl", scale = 0.3,
		name = [=[RGG Helicopter]=], desc = [=[The RGG has tried to taunt us, sending us letters about how their "genius engineers" have created "brilliant aerial killing machines". Let me tell you a secret. Our science business department examined one of these things, and get this! They are literally slot machines glued together into a faint helicopter form. Otherwise, they just have a few guns attached, and a small space for cargo from where it drops (our!) hacked turrets. The pilot doesn't even have a helm, just a lever with which they gamble. We aren't sure how it actually manages to fly, let alone find its way to enemies and shoot them. Our leading theory is that the pilot actually gambles the direction in which to fly and shoot, and gets lucky enough to seem like the helicopter's actually following and targeting you. Either way, unlike our advanced gunships, these things are held together by purple glue bought from a supermarket. Shoot them to your heart's content - they'll drop, soon enough.]=]
	}

	jcms.bestiary.rebel_medic = {
		faction = "rebel", bounty = 35, health = 40,
		mdl = "models/humans/group03m/female_07.mdl", seq = 3, camfov = 30,
		name = [=[Medic]=], desc = [=[Nobody from the RGG has health insurance, and whenever they do, they usually gamble it away. Their solution to this otherwise debilitating socio-economic disaster is to take some water, dye it green, put it in a used medkit (usually stolen from us), and then dump it on the wounded. These guys carry those around, applying the “medkits” to the wounded. It works damn well, and our scientists are also looking into this. One thing you should keep in mind is that gamblers aren’t very smart, so they may think you're on their side. If you manage to not shoot them on sight (they’re purple, I know, but just bear with it for a second), you may even manage to get one of them to heal you.]=]
	}

	jcms.bestiary.rebel_megacopter = {
		faction = "rebel", bounty = 600, health = 2268,
		mdl = "models/combine_helicopter.mdl", mats = { "models/jcms/ultracopter/body", "models/jcms/ultracopter/glass" }, scale = 0.3,
		name = [=[Enforcer Copter]=], desc = [=[Often times whenever J Corp needs something to perform better, we paint it more red, or we give it a business tie and suit, or we change its name to have more J in it, or give it its own little office cubicle. The RGG has picked up on our strategy, and through what we can only assume was the worst shower thought of his life, Traeesen started making even his helicopters gamble, and it has made them a lot more powerful. Apparently, their casinos have special slot machines designed for helicopter use. Helicopters are seemingly really prone to gambling (maybe because they are already slot machines?), and they climbed up the gambling ranks very easily. If you think that RGG symbol on this thing is just a fresh coat of paint, you'd be wrong - they are tattoos, which all RGG Enforcers seem to boast, perhaps as a sign of loyalty. In any case, these things have so much raw gambling power in them that they turn purple from it, and that seems to protect them somehow. But it's nothing a good old "shoot that thing until it explodes" can't solve.]=]
	}

	jcms.bestiary.rebel_odessa = {
		faction = "rebel", bounty = 50, health = 30,
		mdl = "models/odessa.mdl", seq = 7, camfov = 30,
		name = [=[Odessa Cubbage]=], desc = [=[A renowned colonel from a bygone era, Odessa Cubbage bravely led Resistance forces against the Combine during the First Uprising (that was before the Combine was assimilated by J Corp anyway... hence why the Rebels won that war. Cough-cough. Jod, it's such a pity our corporation didn't exist back then. We'd kick everyone back into their cubicals & tax everyone on both sides). Hunters, gunships, striders... You name it. He fucking ripped their brains out with his bare hands and ate them on the spot! Quite a hard-ass he was. When his fists ran out of ammo or weren't available, he'd use his RPG. Apparently, he was just that good, so they sampled his DNA later. So he got flash-cloned - his dirty clothes, RPG and all included - to build an army. Unfortunately his brain kinda degraded, so his clones aren't so tough anymore. That, or the stories he's been telling are full of shit (people took his word for it back in the simpler days). Either way, he's got an RPG, and he was instructed to use it against us. If your aim is any good, you should be able to shoot his rockets down before they reach you.]=]
	}

	jcms.bestiary.rebel_rgg = {
		faction = "rebel", bounty = 25, health = 4,
		mdl = "models/humans/group02/male_05.mdl", mats = { "models/shiny", "models/shiny", "models/shiny", "models/shiny", "models/shiny" }, seq = 14, camfov = 30, color = Color(195, 0, 255),
		name = [=[RGG Grunt]=], desc = [=[If you thought regular RGG rebels are braindead - just wait until you hear this. These guys barely even exist! They scream so much because, once the adrenaline of the battlefield hits their sometimes-there brains, it gets them conscious enough to form their first thoughts. What you care about is that bullets just sort of sometimes don’t work on them, which proved to be troublesome for the earliest of sweeper squads. Fortunately, after intense diplomatic discussions with RGG Ringleader Traeesen, he has made their behaviour deterministic - and now the first few attacks against them will straight up phase through, but the next one will instantly kill them. In other words, they don't have "HP", they have a limited number of hits they can tank, no matter how strong. I know it might be hard for you not to unload 3 whole rockets into whatever you see, but we advise using cheaper ammo against these guys. It is good for business.]=]
	}

	jcms.bestiary.rebel_vanguard = {
		faction = "rebel", bounty = 45, health = 65,
		mdl = "models/humans/group03/male_05.mdl", seq = 1, camfov = 30, color = Color(90, 69, 110),
		name = [=[Vanguard]=], desc = [=[Wait, you're telling me this guy's part of my gan- I mean part of the RGG? Really? Is he like registered and everything? I don't know who the hell this guy is. I mean, I don't have to, of course... I'm part of J Corp... Uh, what does he do exactly? Okay, he's got a shotgun, and his ammo is... on fire? Is the fire even purple? Well, I'll talk to him and fix that later. Okay, he leaves fire where he shoots, so be careful. He shouldn't be much of a problem otherwise, I think.]=]
	}

	jcms.bestiary.rebel_vortigaunt = {
		faction = "rebel", bounty = 90, health = 100,
		mdl = "models/vortigaunt.mdl", camfov = 30,
		name = [=[Vortigaunt]=], desc = [=[I never really got why the RGG is just sometimes... green? I mean, I'm pretty sure they share our instincts of wanting to kill literally everything that isn't their primary color. It's like they think green is purple. Anyway, take them out before they attack you. Their beams deal massive damage, and they make you see things. I got hit by one once and I had these weird visions that still keep me up at night. Visions about angels, turn based tactical gameplay, a weird flower in the sky, my exact IP adress and home location - well, maybe the last part wasn't related. You should also know that these perfectly human jitizens will aid their fellow gamblers by granting them green shields, and because all of you ragtag sweepers probably have some history of gambling, with the right timing, you could abuse this to fully restore your shields and get right back in action.]=]
	}

-- // }}}

-- // Zombies {{{

	jcms.bestiary.zombie_boomer = {
		faction = "zombie", bounty = 25, health = 37,
		mdl = "models/player/zombie_soldier.mdl", seq = 5, color = Color(200, 255, 200), camfov = 30,
		name = [=[Boomer]=], desc = [=[Boomers are zombies that have been infected with Blastcrabs. Almost 80% of their body mass is just rotten blood and young Blastcrabs. They barely have any muscles left in them to raise a hand at you, but they will burst from overstimulation when approached, which will release around 7 Blastcrabs into the open. Make sure to shoot boomers, even after they started bursting - this'll kill the blastcrabs inside and leave you with fewer of them to deal with. Killing a boomer via particularly deadly means, such as using explosives or superheated plasma, will ensure no crabs are left for you to worry about. You could also try to use a stunstick on them - that'll knock the Boomer back and prime the blastcrabs inside for a strong explosion! Use it to your advantage.]=]
	}

	jcms.bestiary.zombie_charple = {
		faction = "zombie", bounty = 20, health = 25,
		mdl = "models/zombie/fast.mdl", mats = { "models/charple/charple3_sheet" }, camfov = 30,
		name = [=[Charple]=], desc = [=[Charred, possessed corpses - Charples are a byproduct of a Zombie Spawner feeding on buried bodies and spewing out the remains to the surface. While they're weak and can be killed in a single shot, Charples are relentless and deal a ton of damage. One of them is capable of almost fully destroying a newly-placed turret with a single leap. Be sure to deal with them as soon as possible, but better yet, deal with their source!]=]
	}

	jcms.bestiary.zombie_combine = {
		faction = "zombie", bounty = 40, health = 100,
		mdl = "models/zombie/zombie_soldier.mdl",
		name = [=[Zombine]=], desc = [=[Explosive runners, living bombs, walking detonators. Call them whatever you want. These suicidal bastards are sure to ditch their friends, life, job and savings just to make sure you go down with a blast. If you see one grabbing a grenade from their pocket, do the same. Just without the job part. Also, it's worth mentioning that if you ever stumble upon one who's able to control their inner instincts it's still best to stay away. In close quarter combat they are rather tanky and almost as strong as poison zombies. So watch out for the red, blinking light if you ever see one. Especially in the dark. Some sweepers tend to follow it blindly as if it was an angler fish... do any of you actually fall for that?]=]
	}

	jcms.bestiary.zombie_explodingcrab = {
		faction = "zombie", bounty = 2, health = 10,
		mdl = "models/headcrab.mdl", mats = { "models/jcms/explosiveheadcrab/body" }, camfov = 15,
		name = [=[Blastcrab]=], desc = [=[Headcrabs that likely mutated due to exposure to radiation or have been bio-engineered to explode on contact. They radiate green light, making them easy to spot; still, they're the most dangerous breed of a common headcrab that we know. They produce "Boomer" zombies by latching onto victims, but we're not sure how that happens, given that Blastcrabs usually immediately disappear after the first bite... Maybe it requires a certain stage of maturity? Anyways, the energy contained inside of them can be released into nearby zombies if you happen to punch a Blastcrab with a stunstick mid-air. It's not much, but it'll be enough damage to kill off other headcrabs and severely damage zombies. Good luck.]=]
	}

	jcms.bestiary.zombie_fast = {
		faction = "zombie", bounty = 28, health = 63,
		mdl = "models/zombie/fast.mdl", bodygroups = { [1] = 1 }, camfov = 30,
		name = [=[Fast Zombie]=], desc = [=[At first glance, this zombie variant might not seem all that dangerous, lacking skin and all kinds of outer tissue, but don't fret. What they don't achieve with muscle, they achieve with speed... and numbers. Their howls are enough to drop some sweepers to their knees, but when you see that there's a bunch of them on their way to maul you? Well, beg Jod for mercy and be prepared for quite the blood-shed. Oh, forgot to mention that they can crawl walls & leap at you from about 20 meters away like a cheetah. Sadly, these went extinct 127 years ago.]=]
	}

	jcms.bestiary.zombie_husk = {
		faction = "zombie", bounty = 13, health = 75,
		mdl = "models/zombie/classic.mdl", bodygroups = { [1] = 1 }, camfov = 30,
		name = [=[Husk]=], desc = [=[Unlucky fellows who either got ambushed by a headcrab, or didn't read the real estate contract too carefully. Slow, dumb and aggressive in their past life, they now have a mind-controlling parasite attached to their head making the matters worse. We're not sure why they're all bloody and gutted, though, but we approve of their appearance, since it's red. Deliver these zombies good news that they've been accepted into J Corp by passing the color test. Then blast them in the head with a shotgun to make sure they respawn right in the office - that'll seal the deal. Shoot them anywhere else, though, and that'll prompt the headcrab to latch off.]=]
	}

	jcms.bestiary.zombie_minitank = {
		faction = "zombie", bounty = 45, health = 432,
		mdl = "models/zombie/poison.mdl", bodygroups = { [1] = 1 }, camfov = 25,
		name = [=[Minitank]=], desc = [=[You know how when you got hired as a sweeper, if you weren't already part of J Corp, you just instantly lost all aggression towards J Corp once you started wearing red clothing? Well, same could be said for this guy - he was a professional boxer and, one day, did a little cosplaying. He's still stuck in that cosplay, because now he's part of the zombies until he takes the cosplay off. That doesn't make him any less strong, though (though he does seem to be walking slower like an actual zombie, and also seems to be acting as stupid as one). He can't throw the headcrab at you (it's a plushie, though that doesn't seem to stop the plushie from attacking you once he dies), but he's damn tanky, and his punch will knock anything way back, especially your turrets. Sadly, he still respawns in the cosplay, so you'll have to deal with him until someone finally decides to just take the poor guy's hat off. We've been dealing with him for years, so that seems unlikely to happen. I think there's something about the physics engine? I don't know.]=]
	}

	jcms.bestiary.zombie_poison = {
		faction = "zombie", bounty = 35, health = 263,
		mdl = "models/zombie/poison.mdl", bodygroups = { 1, 1, 1, 1 }, camfov = 30,
		name = [=[Poison Zombie]=], desc = [=[Look. It's 2925. You've played Half Life 9 by now. You know what these guys do. In fact they literally scanned one to make the games. They're slow, they're tanky, they throw poison headcrabs at you. Poison will do a lot of damage that your gear will help you recover from, so don't ask yourself why you're regenerating, and please for the love of Jod don't immediately call a first aid the moment you see your health drop. Just wait a little. I know it's hard - we only require a 2 second attention span from our sweepers (and even then I heard of sweepers bribing our interviewers with as little as a red popsicle) - but please. Also, please don't fucking call reception asking why the headcrabs don't give you J on death. Why would we reward you for that? That literally takes a single bullet. Do you think J grows in trees? Well, I mean, it can, but you get the point.]=]
	}

	local polypMatrix = Matrix()
	polypMatrix:Rotate( Angle(0, 0, 180) )
	jcms.bestiary.zombie_polyp = {
		faction = "zombie", bounty = 50, health = 200,
		mdl = "models/barnacle.mdl", seq = "chew_humanoid", camfov = 20, matrix = polypMatrix, camlookvector = Vector(0, 0, 18),
		name = [=[Polyp]=], desc = [=[Ground-based barnacle offshots. They exude clouds of red toxins all around them, which will obscure vision and damage you. We'd really love to keep them as pets to pollute our cities with ominous red fog for aesthetics, but Polyps can get annoying as fuck. No matter how many times we screamed at them not to let the gas into the offices, they didn't care. We wish the gas was at least useful for the economy, but no, it isn't. So that's it, this is war. Kill them all. Wander into the fog and eviscerate them. Or call a carpet-bombing over the red clouds for all we care.]=]
	}

	jcms.bestiary.zombie_spawner = {
		faction = "zombie", bounty = 250, health = 675,
		mdl = "models/jcms/zombiespawner.mdl", scale = 0.5,
		name = [=[Spawner]=], desc = [=[Demonic growths on the floor that feed on buried corpses. We haven't bothered to study them beyond the basics, but these creatures seem to leech bodies from under the ground, digest whatever's edible, then spew out possessed, charred remains we dubbed "Charples". They lump multiple such charples together into a ball, then shoot it out like a mortar towards any disturbance they feel in the area (you). Spawners don't move and can't defend themselves in any other way. You can tell that one of them is present if you hear periodic, distant screams... And, of course, you'll likely notice the flaming balls of packed Charples coming your way. Spawners are weak to explosives, so carpet-bombing them or using a C4 is a sure way to get rid of one.]=]
	}

	jcms.bestiary.zombie_spirit = {
		faction = "zombie", bounty = 60, health = 80,
		mdl = "models/zombie/fast.mdl", camfov = 30,
		name = [=[Spirit]=], desc = [=[These apparitions are manifestations of rage and anguish, combined with a vast amount of J-energy. While they can't hurt you on their own, they can transport slower zombies by absorbing them and releasing later in your vicinity. You'll know that a spirit is around once you start seeing zombies materialize out of thin air in front of you. J Corp considered hiring these spirits for transporting personnel, but this was rendered impossible by the spirits' incorporeal nature. To put it more simply, we couldn't hire them because they couldn't hold a pen to sign the contract with.]=],
		preDrawModel = function(ent)
			render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )
			render.SetColorModulation(15, 1, 1)
		end,
		postDrawModel = function(ent)
			render.SetColorModulation(1, 1, 1)
			render.OverrideBlend( false )
		end
	}

-- // }}}
