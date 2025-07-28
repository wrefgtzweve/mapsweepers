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

-- // [GENERAL] Rebel-Specific Functions {{{
	function jcms.npc_GetBestHackable(origin, inRadius, npc)
		-- todo Alyx should prioritize smoked ones
		
		local best, bestDist = nil, inRadius or 1000
		local entTbl
		for _, ent in ipairs(ents.FindByClass("jcms_*")) do --NOTE: Assumes all hackables are jcms_. This saves a lot of performance so it's worth it.
			entTbl = ent:GetTable()
			if entTbl.GetHackedByRebels and not entTbl:GetHackedByRebels() and not entTbl.jcms_beingHacked then
				local dist = ent:WorldSpaceCenter():Distance(origin)
				
				if dist < bestDist and (not IsValid(npc) or npc:Visible(ent)) then
					best, bestDist = ent, dist
				end
			end
		end
		
		return best, bestDist
	end

	function jcms.npc_SpawnRebelTurret(pos, angle, kind, boosted, owner)
		local turret = ents.Create("jcms_turret")
		turret:SetPos(pos)
		turret:Spawn()

		turret:SetHackedByRebels(true)

		turret:UpdateTurretKind(kind)
		turret:SetAngles(angle)

		if boosted then 
			turret:SetupBoosted()
		end

		local ed = EffectData()
		ed:SetColor(jcms.factions_GetColorInteger("rebel"))
		ed:SetFlags(0)
		ed:SetEntity(turret)
		util.Effect("jcms_spawneffect", ed)

		local mins = turret:OBBMins()
		local newPos = Vector(pos)
		newPos.z = newPos.z - mins.z + 2 

		turret:SetPos(newPos)

		jcms.npc_UpdateRelations(turret)
		turret:EmitSound("weapons/shotgun/shotgun_cock.wav")
		turret.jcms_owner = owner
		local tData = turret:GetTurretData()
		if tData.postSpawn then 
			tData.postSpawn(turret)
		end

		return turret
	end

	function jcms.npc_RebelPlaceMine(type, npc, pos, angle, attachEnt)
		--Face the NPC to the target
		--Play the give ammo animation

		--Place the mine
		if type == "breach" then 
			local mine = jcms.orders.mine_breach.func(npcOwner, pos, angle, attachEnt) --todo: Un-jank-ify
			mine:SetColor(Color(162, 81, 255))
			mine.Damage = 0 -- So that they cant kill themselves or harm the player suddenly
		elseif type == "mine" then 
			--if attachent dies we die

		elseif type == "c4" then 

		end
	end
	
	function jcms.npc_RebelPlaceJump(pos, angle, targetPos, npcOwner)
		local pad = ents.Create("jcms_jumppad")
		pos.z = pos.z - pad:OBBMins().z
		pad:SetPos(pos)
		pad:SetMaterial("models/jcms/rgg_jumppad")
		pad:SetAngles(angle)
		pad:Spawn()
		pad.jcms_owner = npcOwner

		local ed = EffectData()
		ed:SetColor(jcms.factions_GetColorInteger("rebel"))
		ed:SetFlags(0)
		ed:SetEntity(pad)
		util.Effect("jcms_spawneffect", ed)
		pad.jcms_rebelTargetPoint = targetPos
	end
-- // }}}

-- // [FODDER/GRUNT ENEMIES] Rebel-Specific Functions {{{

	function jcms.npc_RebelGetJumpPos(npc, targetVec)
		local npcPos = npc:GetPos()

		--Hijack antlion navigation to find a path with jumps. 
		local ant = ents.Create("npc_antlion")
		ant:SetPos(npcPos) 
		ant:Spawn()

		ant:NavSetGoalPos( targetVec )
		local wayPoint --todo: Double-check not(ant:GetPathDistanceToGoal() == 0 stops invalid paths. It should, but this is high-stakes since it can crash the game, so I need to be sure.
		local nextPoint
		while not ant:IsCurWaypointGoal() and not(ant:GetPathDistanceToGoal() == 0) do
			wayPoint = ant:GetCurWaypointPos()
			nextPoint = ant:GetNextWaypointPos()
			toNext = (nextPoint - wayPoint):GetNormalized()
			local ang = math.acos(toNext:Dot(jcms.vectorUp))
			if ang < (math.pi * (1/3)) or ang > math.pi * (2/3) then --If we're at a harsh enough angle
				debugoverlay.Cross(wayPoint, 30, 25, Color( 0, 255, 0 ), true)
				break 
			else
				debugoverlay.Cross(wayPoint, 30, 25, Color( 255, 0, 0 ), true)
			end

			ant:AdvancePath()
		end
		ant:Remove()

		return wayPoint, nextPoint
	end

	function jcms.npc_LaunchTowardsPos(npc, targetPos, vertVel)
		vertVel = vertVel or 750

		local npcPos = npc:GetPos()
		local g = physenv.GetGravity().z
		
		local dir = targetPos - npcPos
		dir.z = 0
		local groundLen = dir:Length()
		
		dir:Normalize()
		local height = targetPos.z - npcPos.z

		debugoverlay.Cross(targetPos, 30, 5, Color( 161, 100, 255 ), true)

		local groundVel = (groundLen * g) / ( -vertVel - math.sqrt( vertVel^2 + (2 * g * height)) )

		npc:SetVelocity(Vector(0,0,vertVel))
		timer.Simple(0.1, function() 
			if not IsValid(npc) then return end
			npc:SetVelocity(dir * groundVel)
		end)
	end

	function jcms.npc_rebelSetup(npc)
		npc.jcms_rebelState = jcms.NPC_STATE_REBELIDLE
		npc.jcms_rebelWaitEnd = CurTime()
	end

	function jcms.npc_rebel_think(npc)
		local breachRange = 150

		local npcPos = npc:WorldSpaceCenter()

		-- Breaching {{{
			local doors = ents.FindByClass("*door*")
			for i, door in ipairs(doors) do
				local doorPos = door:WorldSpaceCenter() 
				if doorPos:DistToSqr(npcPos) < breachRange^2 and not door.jcms_rebelBreached then
					local tr = util.TraceLine({
						start = npcPos,
						endpos = doorPos,
						filter = function(ent) 
							return not string.StartsWith(ent:GetClass(), "npc_")
						end
					})

					if tr.Entity == door then 
						door.jcms_rebelBreached = true 
						jcms.npc_RebelPlaceMine("breach", npc, tr.HitPos, tr.HitNormal:Angle(), door)
						break 
					end
				end
			end
		-- }}}

		-- // JumpPad Nav {{{
			--If we can't reach something (our GoalPos, target, etc) check each jumppad to see if we can reach it,
			--then check if we can reach the target from that jumppad's destination(s?).
		-- }}}
		
		--[[
		-- Deploying Jump pads {{{
			--todo: Don't place if there's already a pad
			local enemy = npc:GetEnemy() 
			--Deploy jumppads when we can't reach our enemy. --todo: Find highground when idle?
			if IsValid(enemy) and npc:IsUnreachable(enemy) then 
				local jumpStart, jumpEnd = jcms.npc_RebelGetJumpPos(npc, enemy:GetPos())
				if jumpStart then
					jcms.npc_RebelPlaceJump(jumpStart, angle_zero, jumpEnd, npc)
					--npc:NavSetGoalPos(jumpStart)
					--npc:SetSchedule(SCHED_FORCED_GO_RUN) --Still doesn't quite seem to work? This is temporary anyway so I'll figure that out later.
				
					npc:SetSaveValue("m_vecLastPosition", jumpStart )
					npc:SetSchedule(SCHED_FORCED_GO_RUN)
				end
			end
		-- }}}

		-- Using jump pads {{{
			for i, ent in ipairs(ents.FindInSphere(npcPos, 50)) do
				if ent:GetClass() == "jcms_jumppad" and ent.jcms_rebelTargetPoint then 
					jcms.npc_LaunchTowardsPos(npc, ent.jcms_rebelTargetPoint)

					ent:JumpEffect()
					npc:EmitSound("odessa.nlo_cheer0" .. tostring(math.random(1,3)) )
					break
				end
			end
		-- }}}
		--]]
	end
-- // }}}

-- // [HELICOPTERS] Rebel-Specific Functions {{{

	function jcms.npc_Helicopter_Setup(npc, dropDelay)
		npc.jcms_heli_dmgProgress = 0
		npc.jcms_heli_nextDrop = CurTime() + dropDelay
		npc.jcms_heli_dropTypes = {"smg"}
		
		npc.jcms_ignoreStraggling = true
		npc.jcms_ignoreDefaultDamageEffects = true

		--Nav & AI
		jcms.npc_setupNPCAirNav(npc)
		npc.jcms_npc_HeliTurretPos = vector_origin

		npc:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS) --Don't collide with other air units.
		--TODO: See if the phys_bone_follower is what's causing us to still collide with each-other.
	end

	function jcms.npc_Helicopter_FireBullets(npc, bulletData)
		local enemy = npc:GetEnemy()
		if IsValid(enemy) and not enemy:IsPlayer() then --Work-around for non-player enemy targeting
			bulletData.Dir = (enemy:GetPos() - npc:GetPos()):GetNormalized()
			--bulletData.Spread:Mul(1.5)
		end
	end

	function jcms.npc_Helicopter_TakeDamage(npc, dmg)
		if not(npc:GetNWInt("jcms_sweeperShield", -1) > 0) then --Our workaround bypasses shields, this un-bypasses them.
			dmg:SetDamageType( bit.bor(dmg:GetDamageType(), DMG_AIRBOAT) )
		end

		local lastPhraseTime = npc.lastPhraseTime or 0
		local elapsed = CurTime() - lastPhraseTime

		local damage = dmg:GetDamage()
		npc.jcms_heli_dmgProgress = npc.jcms_heli_dmgProgress + damage

		if elapsed > 4 and npc.jcms_heli_dmgProgress > 150 then
			npc:EmitSound("jcms_rebelheli_hurt", 140, 100, 1, CHAN_VOICE, 0, 38)
			npc.lastPhraseTime = CurTime()
			npc.jcms_heli_dmgProgress = 0
		end
		
		if damage > npc:Health() and not npc.jcms_heliDead then --Force us to die properly/pay bounty
			npc.jcms_heliDead = true --We seem to sometimes get called a fuckload of times at once, giving way too much bounty.
			npc:EmitSound("jcms_rebelheli_die", 140, 100, 1, CHAN_VOICE, 0, 38) --Death line
			hook.Call("OnNPCKilled", GAMEMODE, npc, dmg:GetAttacker(), dmg:GetInflictor())
		end
		
		timer.Simple(0, function()
			if IsValid(npc) then
				npc:SetNWFloat("HealthFraction", npc:Health() / npc:GetMaxHealth())
			end
		end)
	end

	function jcms.npc_Helicopter_Think(npc)
		local enemy = npc:GetEnemy()

		-- // Voice Cues {{{
			local lastPhraseTime = npc.lastPhraseTime or 0
			local elapsed = CurTime() - lastPhraseTime
			
			if enemy then
				if not npc.seenEnemyOnce then
					npc:EmitSound("jcms_rebelheli_spot", 140, 100, 1, CHAN_VOICE, 0, 38)
					npc.lastPhraseTime = CurTime() + 0.25
					npc.seenEnemyOnce = true
				else
					if elapsed > 4 and math.random() < (elapsed-4)*0.09 then
						npc:EmitSound("jcms_rebelheli_taunt", 140, 100, 1, CHAN_VOICE, 0, 38)
						npc.lastPhraseTime = CurTime()
					end
				end
			else
				if elapsed > 5 and math.random() < (elapsed-5)*0.1 then
					npc:EmitSound("jcms_rebelheli_idle", 140, 100, 1, CHAN_VOICE, 0, 38)
					npc.lastPhraseTime = CurTime()
				end
			end
		-- // }}}
		
		if IsValid(enemy) and npc:Visible(enemy) then
			local lastShootingTime = npc.lastShootingTime or 0
			local elapsedShooting = CurTime() - lastShootingTime

			if elapsedShooting > 9 then
				npc:EmitSound("NPC_AttackHelicopter.ChargeGun")
				npc:SetSaveValue("m_flChargeTime", 1.7)
				npc:SetSaveValue("m_nGunState", 1) 
				npc:SetSaveValue("m_flCircleOfDeathRadius", 360)
				npc.lastShootingTime = CurTime()
			end
		end

		npc:SetSaveValue("m_vecDesiredPosition", npc:GetPos())
		if npc.jcms_npcState == jcms.NPC_STATE_AIRNAVIGATE then 
			jcms.npc_airNavigateThink(npc, 200)
		elseif npc.jcms_npcState == jcms.NPC_STATE_HELIPLACE then --nav to our target & place turret
			npc:SetSaveValue("m_vecDesiredPosition", npc.jcms_npc_HeliTurretPos)

			if npc:GetPos():DistToSqr(npc.jcms_npc_HeliTurretPos) < 25^2 then 
				npc:EmitSound("NPC_AttackHelicopter.DropMine")
				local type = npc.jcms_heli_dropTypes[1] 
				jcms.npc_SpawnRebelTurret(npc:GetPos() - Vector(0,0,150), angle_zero, type, npc)
				npc.jcms_heli_nextDrop = CurTime() + 30

				npc.jcms_npcState = jcms.NPC_STATE_AIRIDLE
			end
		else
			jcms.npc_airThink(npc)

			--max 20 turrets, and are we ready to drop another
			if npc.jcms_heli_nextDrop < CurTime() and jcms.npc_Helicotper_GetTurretCount() < 20 then
				local nav = navmesh.GetNearestNavArea(npc:GetPos(), false, 10000, true, false )

				if nav then
					--todo Better collision avoidance (chosen pos could be next to a wall)
					--Maybe play a sound here as well?
					npc.jcms_npc_HeliTurretPos = jcms.npc_Helicopter_GetGoodTurretPos(nav) + Vector(0,0,600)
					
					npc.jcms_npcState = jcms.NPC_STATE_HELIPLACE
				end
			end
		end
	end

	function jcms.npc_Helicotper_GetTurretCount()
		local count = 0
		for i, turret in ipairs(ents.FindByClass("jcms_turret")) do
			count = count + ((turret:GetHackedByRebels() and 1) or 0)
		end
		return count
	end

	function jcms.npc_Helicopter_GetGoodTurretPos(navArea) --used in think
		local bestAdj = 0
		local bestCount = math.huge
		for i=0, 3, 1 do
			local adjCount = navArea:GetAdjacentCountAtSide( i )
			if bestCount > adjCount then --optimally we want 0, as that's probably an edge.
				bestCount = adjCount
				bestAdj = i
			end
		end
		
		local edgePos = jcms.mapgen_GetAreaEdgePos(navArea, bestAdj)

		local cDir = (navArea:GetCenter() - edgePos):GetNormalized()
		
		return edgePos + cDir * 40 --Don't place us *exactly* on the edge, give us a little space.
	end
	
-- // }}}

-- // {{{ Enums for custom behaviours
	jcms.NPC_STATE_REBELIDLE = 0
	--jcms.NPC_STATE_REBELWAIT = 1

	jcms.NPC_STATE_HELIPLACE = 2
-- // }}}

--[[todo/NOTE: 
	Make rebels plant C4 and Mines on things
		--When they get a mine/C4 planted on them they should just start screaming and running at the player.

	Jumppads

	Make rebels shoot mines
		--Make mines have HP and only take damage from enemies. This will have to be handled relatively carefully so that it
		doesn't cause random-feeling detonations.

		--Make rebels apply bullseyes to nearby mines. 
--]]

-- // Sounds {{{

	sound.Add( {
		name = "jcms_rebelheli_idle",
		channel = CHAN_VOICE,
		volume = 1.0,
		level = 150,
		pitch = 100,
		sound = {
			"vo/npc/male01/answer15.wav",
			"vo/npc/male01/answer18.wav",
			"vo/npc/male01/answer19.wav",
			"vo/npc/male01/answer29.wav",
			"vo/npc/male01/answer30.wav",
			"vo/npc/male01/getgoingsoon.wav",
			"vo/npc/male01/gordead_ans13.wav",
			"vo/npc/male01/gordead_ans15.wav",
			"vo/npc/male01/hi01.wav",
			"vo/npc/male01/holddownspot01.wav",
			"vo/npc/male01/holddownspot02.wav",
			"vo/npc/male01/imstickinghere01.wav",
			"vo/npc/male01/okimready01.wav",
			"vo/npc/male01/question02.wav",
			"vo/npc/male01/question03.wav",
			"vo/npc/male01/question04.wav",
			"vo/npc/male01/question05.wav",
			"vo/npc/male01/question06.wav",
			"vo/npc/male01/question07.wav"
		}
	} )
	
	sound.Add( {
		name = "jcms_rebelheli_taunt",
		channel = CHAN_VOICE,
		volume = 1.0,
		level = 150,
		pitch = 100,
		sound = {
			"vo/npc/male01/evenodds.wav",
			"vo/npc/male01/gethellout.wav",
			"vo/npc/male01/gordead_ques17.wav",
			"vo/npc/male01/heretohelp02.wav",
			"vo/npc/male01/likethat.wav",
			--"vo/npc/male01/no02.wav", --(Moved to hurt)
			"vo/npc/male01/gordead_ans17.wav",
			"vo/npc/male01/notthemanithought01.wav",
			--"vo/npc/male01/ok02.wav",
			--"vo/npc/male01/overhere01.wav",
			"vo/npc/male01/question16.wav",
			"vo/npc/male01/question17.wav",
			"vo/npc/male01/question21.wav",
			"vo/npc/male01/runforyourlife01.wav",
			"vo/npc/male01/runforyourlife02.wav",
			--"vo/npc/male01/squad_affirm06.wav",
			--"vo/npc/male01/squad_away01.wav",
			--"vo/npc/male01/stopitfm.wav", --(Moved to hurt)
			"vo/npc/male01/strider_run.wav",
			"vo/npc/male01/thislldonicely01.wav",
			"vo/npc/male01/vquestion01.wav",
			"vo/npc/male01/watchwhat.wav",
			"vo/npc/male01/wetrustedyou01.wav",
			"vo/npc/male01/wetrustedyou02.wav",
			"vo/npc/male01/yeah02.wav"
		}
	} )
	
	sound.Add( {
		name = "jcms_rebelheli_spot",
		channel = CHAN_VOICE,
		volume = 1.0,
		level = 150,
		pitch = 100,
		sound = {
			"vo/npc/male01/gordead_ques03b.wav",
			"vo/npc/male01/gordead_ques03a.wav",
			"vo/npc/male01/gordead_ques05.wav",
			--"vo/npc/male01/gotone01.wav",
			--"vo/npc/male01/gotone02.wav",
			"vo/npc/male01/heretheycome01.wav",
			"vo/npc/male01/incoming02.wav",
			--"vo/npc/male01/okimready03.wav",
			"vo/npc/male01/overhere01.wav",
			"vo/npc/male01/overthere02.wav",
			--"vo/npc/male01/squad_away01.wav",
			"vo/npc/male01/upthere02.wav",
			"vo/canals/shanty_yourefm.wav",
			"vo/canals/male01/gunboat_owneyes.wav",
			"vo/canals/male01/stn6_incoming.wav",
			"vo/coast/cardock/le_gotgordon.wav",
			"vo/npc/male01/abouttime01.wav",
			--"vo/npc/male01/ahgordon02.wav"
		}
	} )

	sound.Add( {
		name = "jcms_rebelheli_hurt",
		channel = CHAN_VOICE,
		volume = 1.0,
		level = 150,
		pitch = 100,
		sound = {
			"vo/npc/male01/stopitfm.wav",
			"vo/npc/male01/no02.wav",
			"vo/npc/male01/gordead_ans04.wav",
			"vo/npc/male01/gordead_ans05.wav",
			"vo/npc/male01/gordead_ans07.wav",
			"vo/npc/male01/help01.wav",
			"vo/npc/male01/hitingut01.wav",
			"vo/npc/male01/imhurt02.wav",
			"vo/npc/male01/onyourside.wav",
			"vo/npc/male01/myleg01.wav",
			"vo/npc/male01/myarm01.wav"
		}
	} )
	
	sound.Add( {
		name = "jcms_rebelheli_die",
		channel = CHAN_VOICE,
		volume = 1.0,
		level = 150,
		pitch = 100,
		sound = {
			--"vo/canals/matt_closecall.wav",
			--"vo/canals/premassacre.wav",
			"vo/canals/male01/gunboat_farewell.wav",
			"vo/coast/odessa/male01/nlo_cubdeath01.wav",
			"vo/coast/odessa/male01/nlo_cubdeath02.wav",
			"vo/npc/male01/gordead_ans02.wav",
			"vo/npc/male01/gordead_ques14.wav",
			--"vo/npc/male01/gordead_ans17.wav" -- That's not Gordon Freeman
		}
	} )
-- // }}}

jcms.npc_types.rebel_rgg = {
	portalSpawnWeight = 0.5,
	faction = "rebel",
	
	danger = jcms.NPC_DANGER_FODDER,
    cost = 0.9,
    swarmWeight = 0.3,

	class = "npc_citizen",
	bounty = 25,

	weapons = {
		weapon_pistol = 3,
		weapon_smg1 = 1,
		--weapon_stunstick = 1 --Melee might've been cool, but they work terribly.
	},
	
	postSpawn = function(npc)
		local color = Color(math.random(140, 150), 0, math.random(209, 230), 100)
		npc:SetMaterial("models/shiny")
		npc:SetColor(color)
		npc:SetRenderMode(RENDERMODE_TRANSCOLOR)
		npc:SetRenderFX( 15 ) --Enum for this doesn't exist? Or at least my editor doesn't highlight it for some reason.
		
		local wep = npc:GetActiveWeapon()
		if IsValid(wep) then
			wep:SetMaterial("models/shiny")
			wep:SetColor(color)
			wep:SetRenderMode(RENDERMODE_TRANSCOLOR)
			wep:SetRenderFX( 15 )
		end

		npc:SetMaxHealth(4) --If we really want randomness with this enemy, it should be this part.
		npc:SetHealth(npc:GetMaxHealth())

		npc.jcms_rgg_nextTeleport = CurTime()
		npc.jcms_rgg_teleporting = false
	end,
	
	takeDamage = function(npc, dmg)
        dmg:SetDamageType(DMG_DISSOLVE)
		if dmg:GetDamage() > 0 then
			dmg:SetDamage(1)
		end
    end,
    
    think = function(npc)
		--Could split into smaller grunts if they're still an uninteresting enemy. This should hopefully be good enough though.

		if npc.jcms_rgg_teleporting then 
			if npc:GetPathDistanceToGoal() > 0 then --SAFETY! If we lose our path between this/next think this could crash us.
				local start = npc:WorldSpaceCenter()

				local waypoint = npc:GetNextWaypointPos()
				if waypoint:LengthSqr() > 1 then -- They may sometimes teleport to world origin if waypoint is invalid.
					npc:SetPos(waypoint)
					npc:AdvancePath()

					local ed = EffectData()
					ed:SetFlags(3)
					ed:SetEntity(npc)
					ed:SetOrigin(start)
					util.Effect("jcms_chargebeam", ed)
				else
					npc.jcms_rgg_teleporting = false
				end
			end

			npc.jcms_rgg_teleporting = false
		end

		if npc.jcms_rgg_nextTeleport < CurTime() and npc:GetPathDistanceToGoal() > 150 then 
			npc.jcms_rgg_teleporting = true

			--Make a bunch of tesla effects on us before we teleport.
			local ed = EffectData()
			ed:SetEntity(npc)
			ed:SetScale(1.1) --Activation time
			util.Effect("jcms_electricarcs", ed)

			npc.jcms_rgg_nextTeleport = CurTime() + 2.5
		end

		if math.random() < 0.7 then
			local t = { "npc_citizen.no01", "npc_citizen.no02", "npc_citizen.die", "npc_citizen.uhoh" }
			
			npc:EmitSound(t[math.random(1, #t)])
		end
    end,

	proficiency = WEAPON_PROFICIENCY_GOOD
}

jcms.npc_types.rebel_fighter = {
	portalSpawnWeight = 1.25,
	faction = "rebel",
	
	danger = jcms.NPC_DANGER_FODDER,
    cost = 1,
    swarmWeight = 1,

	class = "npc_citizen",
	bounty = 30,

	weapons = {
		weapon_smg1 = 4,
		weapon_ar2 = 2,
		weapon_pistol = 1
	},
	
	preSpawn = function(npc)
		npc:SetKeyValue("citizentype", "3")
	end,
	
	postSpawn = function(npc)
		npc:SetMaxHealth( npc:Health() + 5 )
		npc:SetHealth( npc:GetMaxHealth() )
		npc:Fire("SetMedicOn") 
	end,

	think = function(npc) 
		jcms.npc_rebel_think(npc)
	end,

	proficiency = WEAPON_PROFICIENCY_VERY_GOOD
}

jcms.npc_types.rebel_medic = {
	portalSpawnWeight = 0.75,
	faction = "rebel",
	
	danger = jcms.NPC_DANGER_FODDER,
    cost = 1,
    swarmWeight = 1,

	class = "npc_citizen",
	bounty = 35,

	weapons = {
		weapon_shotgun = 3,
		weapon_smg1 = 2,
		weapon_ar2 = 1
	},
	
	preSpawn = function(npc)
		npc:SetKeyValue("citizentype", "3")
		npc:SetKeyValue("spawnflags", bit.bor(npc:GetKeyValues().spawnflags, 131072))
	end,
	
	postSpawn = function(npc)
		npc:Fire("SetMedicOn")
		
		if npc:GetActiveWeapon():GetClass() == "weapon_shotgun" then 
			npc:SetSaveValue("m_flDistTooFar", 500)
		end
	end,
	
	think = function(npc)
		jcms.npc_rebel_think(npc)
	end,

	proficiency = WEAPON_PROFICIENCY_VERY_GOOD
}

jcms.npc_types.rebel_vanguard = {
	portalSpawnWeight = 0.1,
	faction = "rebel",
	
	danger = jcms.NPC_DANGER_STRONG,
    cost = 1.5,
    swarmWeight = 0.55,
    swarmLimit = 1,

	class = "npc_citizen",
	bounty = 45,

	weapons = {
		weapon_shotgun = 1
	},
	
	preSpawn = function(npc)
		npc:SetKeyValue("citizentype", "3")
	end,
	
	postSpawn = function(npc)
		npc:SetMaxHealth( npc:Health() + 25 )
		npc:SetHealth( npc:GetMaxHealth() )
		--npc.jcms_hasSmokeGrenade = true
		npc:Fire("SetMedicOn")

		npc:SetMaxLookDistance(1000)
		npc:SetArrivalDistance(250)

		npc:SetSaveValue("m_flDistTooFar", 500)
		npc:GetActiveWeapon():SetSaveValue("m_fMinRange1", 0)
		npc:GetActiveWeapon():SetSaveValue("m_fMaxRange1", 750)

		-- // Visuals {{{ 
			npc:SetColor(color_black)

			local ed = EffectData()
			ed:SetEntity(npc)
			ed:SetScale(0)
			ed:SetStart( jcms.vectorOrigin )
			util.Effect("jcms_burningcharacter", ed)
		-- // }}}

		npc:EmitSound("streetwar.fire_medium")
		--npc/zombie/moan_loop1.wav (1-4)
	end,

	takeDamage = function(npc, dmgInfo) 
		if not(bit.band(dmgInfo:GetDamageType(), bit.bor(DMG_BURN, DMG_SLOWBURN) ) == 0) then 
			npc:Extinguish() --If we can't actually ignite ourselves then might as well.
			dmgInfo:SetDamage(0)
		end
	end,
	
	--[[
	think = function(npc, state)
		local smokeRange = 3500
		if (npc.jcms_hasSmokeGrenade) and (state == NPC_STATE_COMBAT) and (IsValid(npc:GetEnemy()) and npc:GetEnemy():WorldSpaceCenter():DistToSqr(npc:EyePos()) < smokeRange*smokeRange) then
			local nadeTarget = npc:GetEnemy():GetPos()
			npc:SetIdealYaw((nadeTarget - npc:EyePos()):Angle().y)
			npc:SetSchedule(SCHED_MELEE_ATTACK1)
			
			timer.Simple(0.5, function()
				if IsValid(npc) and npc:Health() > 0 then
					local npcPos = npc:WorldSpaceCenter()
					local nadeDir = Vector(nadeTarget)
					nadeDir:Sub(npcPos)
					nadeDir:Normalize()
					
					npc.jcms_hasSmokeGrenade = false
					local nade = ents.Create("jcms_smokenade")
					nade:SetPos(npcPos)
					nade:SetOwner(npc)
					nade:Spawn()
					
					nadeDir:Mul(900)
					nadeDir.z = nadeDir.z + 75
					nade:GetPhysicsObject():SetVelocity(nadeDir)
					nade:GetPhysicsObject():SetAngleVelocity(Vector(-32, 32))
					npc:SetSchedule(SCHED_BACK_AWAY_FROM_ENEMY)
				end
			end)
		end
	end,--]]

	entityFireBullets = function(npc, bulletData)
		bulletData.TracerName = nil
		bulletData.Tracer = math.huge

		bulletData.Spread = Vector(0.1,0.1,0)
		bulletData.Num = 11

		bulletData.Dir:Sub( Vector(0,0,0.05) ) --Aim down just a little bit to hit the ground more.

		bulletData.Callback = function(attacker, tr, dmgInfo)
			local effectdata = EffectData()
			effectdata:SetStart(LerpVector(7/tr.StartPos:Distance(tr.HitPos), tr.StartPos, tr.HitPos))
			effectdata:SetScale(math.random(6500, 9000))
			effectdata:SetAngles(tr.Normal:Angle())
			effectdata:SetOrigin(tr.HitPos)
			effectdata:SetFlags(1)
			util.Effect("jcms_laser", effectdata)

			dmgInfo:SetDamageType( bit.bor(dmgInfo:GetDamageType(), DMG_BURN) )

			if tr.HitWorld and tr.HitNormal:Dot(jcms.vectorUp) > 0 then --Hit world, and not a vertical wall or ceiling.
				local fire = ents.Create("jcms_fire")
				fire:SetPos(tr.HitPos)
				fire:Spawn()

				fire:SetRadius(45)
				fire:SetActivationTime(CurTime() + 3)
				fire.dieTime = CurTime() + 14
			elseif tr.Entity and not tr.Entity:IsOnFire() and not tr.Entity:IsPlayer() then 
				tr.Entity:Ignite(1.5)
			end
		end
	end,

	proficiency = WEAPON_PROFICIENCY_GOOD
}

--[[
jcms.npc_types.rebel_engineer = {
	portalSpawnWeight = 0.1,
	faction = "rebel",
	
	danger = jcms.NPC_DANGER_STRONG,
    cost = 1.5,
    swarmWeight = 0.5,
    swarmLimit = 1,

	class = "npc_citizen",
	bounty = 45,

	weapons = {
		weapon_shotgun = 1
	},

	preSpawn = function(npc)
		npc:SetKeyValue("citizentype", "3")
	end,

	postSpawn = function(npc)
		npc:Fire("SetMedicOn")

		npc:SetMaxLookDistance(1000)
		npc:SetArrivalDistance(250)

		npc:SetSaveValue("m_flDistTooFar", 500)
		npc:GetActiveWeapon():SetSaveValue("m_fMinRange1", 0)
		npc:GetActiveWeapon():SetSaveValue("m_fMaxRange1", 750)

		--backpack charger / tesla
		npc.backpack = ents.Create("jcms_vanguard_backpack")
		local attch = npc:GetAttachment(3)
		npc.backpack:SetPos(attch.Pos - attch.Ang:Forward() * 11 - attch.Ang:Up() * 20)
		npc.backpack:SetAngles(attch.Ang)
		npc.backpack:SetParent(npc, 3)
		npc.backpack:Spawn()
		npc.backpack.jcms_owner = npc

		local ed = EffectData()
		ed:SetEntity(npc)
		ed:SetScale(0) --Activation time
		util.Effect("jcms_electricarcs", ed)
	end,

	takeDamage = function(npc, dmgInfo)
		timer.Simple(0, function()
			if IsValid(npc) and IsValid(npc.backpack) and npc:Health() <= 0 then 
				npc.backpack:Remove()
			end
		end)
	end,

	think = function(npc, state)
		--Place mines, C4.
		--Any other objects that are relevant.
	end,
	
	entityFireBullets = function(npc, bulletData)
		bulletData.IgnoreEntity = npc.backpack
	end
}
--]]

jcms.npc_types.rebel_odessa = {
	portalSpawnWeight = 0.5,
	faction = "rebel",
	
	danger = jcms.NPC_DANGER_FODDER,
    cost = 1.6,
    swarmWeight = 0.5,
    swarmLimit = 1,

    model = "models/odessa.mdl",
	class = "npc_citizen",
	bounty = 50,

	weapons = {
		--weapon_rpg = 1
		weapon_jcms_rpg = 1
	},
	
	postSpawn = function(npc)
		npc:Fire("SetMedicOn") --todo: Maybe we should give RPG ammo instead

		npc:SetMaxLookDistance(5000)
		npc:SetArrivalDistance(4000)
		npc:SetKeyValue("ignoreunseenenemies", "1")

		npc:SetMaxHealth(math.ceil(npc:GetMaxHealth() * 0.75))
		npc:SetHealth(npc:GetMaxHealth())
		
		npc:GetActiveWeapon():SetSaveValue("m_fMinRange1", 1000)
		npc:GetActiveWeapon():SetSaveValue("m_fMaxRange1", 4000)
		npc:SetSaveValue("m_flDistTooFar", 5000)

		npc.jcms_odessa_nextFlee = CurTime()
	end,
	
	think = function(npc, state)
		local minRange = 1000 --Run if we're within this distance.
		
		local enemy = npc:GetEnemy()
		if IsValid(enemy) and npc.jcms_odessa_nextFlee < CurTime()  then
			local enemyPos = enemy:GetPos()
			local npcPos = npc:GetPos()
			local dist = enemyPos:Distance(npcPos)
			if dist < minRange then 
				local toUs =  (npcPos - enemyPos):GetNormalized()

				npc:SetSaveValue("m_vecLastPosition", npcPos + toUs * (minRange - dist) )
				npc:SetSchedule(SCHED_FORCED_GO_RUN)

				npc.jcms_odessa_nextFlee = CurTime() + 5
			end
		end
	end,

	proficiency = WEAPON_PROFICIENCY_VERY_GOOD
}

jcms.npc_types.rebel_alyx = { --todo: Stun when hit w/stunstick
	portalSpawnWeight = 0.2,
	faction = "rebel",
	
	danger = jcms.NPC_DANGER_STRONG,
    cost = 1.5,
    swarmWeight = 0.6,
    swarmLimit = 3,

	class = "npc_alyx",
	bounty = 75,

	weapons = {
		weapon_alyxgun = 1,
	},
	
	postSpawn = function(npc)
		npc:SetMaxHealth(65)
		npc:SetHealth(npc:GetMaxHealth())

		npc.jcms_slowTurretReact = true

		npc.jcms_alyxHealth = npc:GetMaxHealth()
		npc.jcms_alyxActivation = CurTime() + 4

		npc.jcms_dmgMult = 0.5

		npc:SetMaxLookDistance(1000)
		npc:SetArrivalDistance(250)
		
		npc:GetActiveWeapon():SetSaveValue("m_fMaxRange1", 1000)
		npc:SetSaveValue("m_flDistTooFar", 1000)
	end,

	takeDamage = function(npc, dmg) --Alyx self-heals and there's no way (that I've found in the documentation) to disable that. This is a work-around because that's awful.
		if jcms.util_IsStunstick( dmg:GetInflictor() ) then
			dmg:ScaleDamage(2)
		end
		
		npc.jcms_alyxHealth = npc.jcms_alyxHealth - dmg:GetDamage()
		if npc.jcms_alyxHealth < 0 and not npc.jcms_alyxDead then 
			npc.jcms_alyxDead = true

			dmg:SetDamage(npc:GetMaxHealth())
			timer.Simple(0, function()
				if IsValid(npc) then 
					npc:TakeDamage(npc:GetMaxHealth())
				end
			end)
			
			local force = dmg:GetDamageForce()
			force:Mul(100)

			dmg:SetDamageForce(force)

			npc:TakeDamageInfo(dmg)
		end
	end,
	
	think = function(npc, state)
		if (state < NPC_STATE_IDLE) or (state > NPC_STATE_COMBAT) then
			return
		end
		if npc.jcms_alyxActivation > CurTime() then return end 
		
		local hackTarget, hackDist
		if IsValid(npc.jcms_hackTarget) then
			hackTarget = npc.jcms_hackTarget
			hackDist = npc:WorldSpaceCenter():Distance(hackTarget:WorldSpaceCenter())
		else
			npc.jcms_hackTarget = nil
			hackTarget, hackDist = jcms.npc_GetBestHackable(npc:WorldSpaceCenter(), 1300, npc)
		end
		
		if IsValid(hackTarget) then
			if (npc:Health() > 0) then
				npc.jcms_hackTarget = hackTarget
				if hackDist > 300 then
					npc:SetSaveValue("m_vecLastPosition", hackTarget:GetPos())
					
					if npc:GetCurrentSchedule() ~= SCHED_FORCED_GO_RUN then
						npc:SetSchedule(SCHED_FORCED_GO_RUN)
					end
				else
					npc.jcms_hackTarget = nil
					hackTarget.jcms_beingHacked = true
					npc:AddGestureSequence(2085)
					
					timer.Simple(0.9, function()
						if IsValid(npc) and IsValid(hackTarget) and (hackTarget.SetHackedByRebels) and (npc:Health() > 0) then
							-- This tended to crash the game.
							--[[npc:EmitSound("AlyxEMP.Discharge")
							
							local emptool = npc:GetInternalVariable("m_hEmpTool")
							local ed = EffectData()
							local angpos = npc:GetAttachment( npc:LookupAttachment("anim_attachment_LH") )
							ed:SetStart(hackTarget:WorldSpaceCenter())
							ed:SetOrigin(IsValid(emptool) and emptool:WorldSpaceCenter() or (angpos and angpos.Pos) or npc:WorldSpaceCenter())
							util.Effect("jcms_tesla", ed)]]

							local ed = EffectData()
							ed:SetEntity(hackTarget)
							ed:SetFlags(1)
							ed:SetColor(jcms.factions_GetColorInteger("rebel"))
							util.Effect("jcms_shieldeffect", ed)
						end
					end)
					
					timer.Simple(1.3, function()
						if IsValid(hackTarget) then
							hackTarget.jcms_beingHacked = nil
						end
						
						if IsValid(npc) and IsValid(hackTarget) and (hackTarget.SetHackedByRebels) and (npc:Health() > 0) then
							hackTarget:EmitSound("npc/assassin/ball_zap1.wav", 75, 90)
							hackTarget:SetHackedByRebels(true)

							if hackTarget:GetClass() == "jcms_turret" then 
								hackTarget:SetTurretAlert(0)
							end

							if hackTarget:GetNWInt("jcms_sweeperShield_max", -1) > 0 then
								hackTarget:SetNWInt("jcms_sweeperShield_colour", jcms.factions_GetColorInteger("rebel"))
							end
							
							if hackTarget:IsNPC() then
								jcms.npc_UpdateRelations(hackTarget)
							end
						end
					end)
				end
			end
		end
	end,

	proficiency = WEAPON_PROFICIENCY_GOOD
}

jcms.npc_types.rebel_dog = {
	portalSpawnWeight = 0.08,
	faction = "rebel",
	
	danger = jcms.NPC_DANGER_STRONG,
    cost = 3,
    swarmWeight = 0.4,
    swarmLimit = 2,

	class = "npc_jcms_dog",
	bounty = 135,
	
	portalScale = 3
}

jcms.npc_types.rebel_vortigaunt = {
	portalSpawnWeight = 0.08,
	faction = "rebel",
	
	danger = jcms.NPC_DANGER_STRONG,
    cost = 1.8,
    swarmWeight = 0.55,

	class = "npc_vortigaunt",
	bounty = 90,
	
	portalScale = 1.25,
	postSpawn = function(npc)
		npc.jcms_dmgMult = 0.3
		
		npc:SetMaxLookDistance(1000)
		npc:SetArrivalDistance(250)

		npc.jcms_vortCharging = false 
		
		npc.jcms_vortNextCharge = CurTime() + 12.5


		local timerName = "jcms_vort_fastThink_" .. tostring(npc:EntIndex())
		timer.Create(timerName, 0.05, 0, function() 
			if not IsValid(npc) then 
				timer.Remove(timerName)
				return 
			end
			
			local sched = npc:GetCurrentSchedule()
			if npc.jcms_vortCharging then --todo: Doesn't quite work. We want to stop them from attacking/snapping right after this.
				npc:SetSchedule(17)
				npc:SetSequence(66)
			end

			if sched == 262 or sched == 162 then 
				npc:SetPlaybackRate(0.35)
			else
				npc:SetPlaybackRate(1)
			end
		end)
	end,
	
	think = function(npc, state)
		if npc.jcms_vortNextCharge < CurTime() and not npc.jcms_vortCharging then --Apply shields every 30s
			local targetCount = 0
			for i, ent in ipairs(ents.FindInSphere(npc:GetPos(), 175)) do
				if (ent:IsPlayer() or ent:IsNPC()) and not (nt == npc) then 
					targetCount = targetCount + 1
				end
			end
			if targetCount == 0 then return end

			npc:AddGestureSequence(66)
			npc.jcms_vortCharging = true
			timer.Simple(1.8, function()
				if IsValid(npc) then
					npc.jcms_vortCharging = false

					npc:EmitSound("npc/vort/attack_shoot.wav", 100, 90, 1)
					for i, ent in ipairs(ents.FindInSphere(npc:GetPos(), 300)) do
						if ent:IsPlayer() then 
							ent:SetArmor(ent:GetMaxArmor())

							local ed = EffectData()
							ed:SetEntity(ent)
							ed:SetFlags(2)
							ed:SetColor(jcms.util_ColorIntegerFast(0, 255, 0))
							util.Effect("jcms_shieldeffect", ed)
							ent:EmitSound("items/suitchargeok1.wav", 50, 130, 0.5)
						elseif ent:IsNPC() and not(ent:GetNWInt("jcms_sweeperShield_max") == -1) and ent:GetMaxHealth() < 100 then
							--30 max, 5 regen, 1.5 delay (like an elite)
							jcms.npc_SetupSweeperShields(ent, 30, 5, 1.5, Color(120, 255, 120))
						end
					end
				end
			end)

			npc.jcms_vortNextCharge = CurTime() + 22.5
		end
	end
}

jcms.npc_types.rebel_helicopter = {
	faction = "rebel",
	
	danger = jcms.NPC_DANGER_BOSS,
	cost = 5.5,
	swarmWeight = 0.5,
	swarmLimit = 1,
	aerial = true,

	class = "npc_helicopter",
	bounty = 400,
	portalScale = 5,
	
	postSpawn = function(npc)
		--NOTE: Sometimes randomly instantly dies. 
			-- promoted. -MerekiDor
		jcms.npc_Helicopter_Setup(npc, 40)
		npc:SetNWString("jcms_boss", "rebel_helicopter")

		npc:SetMaxHealth(npc:GetMaxHealth() * 0.4)
		npc:SetHealth(npc:GetMaxHealth())
	end,

	think = function(npc, state)
		jcms.npc_Helicopter_Think(npc)
	end,

	takeDamage = function(npc, dmg)
		jcms.npc_Helicopter_TakeDamage(npc, dmg)
    end,

	entityFireBullets = function(npc, bulletData)
		jcms.npc_Helicopter_FireBullets(npc, bulletData)
	end,

	check = function(director)
		return jcms.npc_capCheck("npc_helicopter", 12) and jcms.npc_airCheck()
	end
}

jcms.npc_types.rebel_megacopter = {
	faction = "rebel",
	
	danger = jcms.NPC_DANGER_RAREBOSS,
	cost = 6,
	swarmWeight = 0.5,
	swarmLimit = 1,
	aerial = true,

	class = "npc_helicopter",
	bounty = 600,
	portalScale = 5,
	
	postSpawn = function(npc)
		jcms.npc_Helicopter_Setup(npc, 40)
		npc:SetNWString("jcms_boss", "rebel_megacopter")

		npc.jcms_heli_dropTypes[1] = "gatling"

		npc:SetMaxHealth(npc:GetMaxHealth() * 0.45)
		npc:SetHealth(npc:GetMaxHealth())

		jcms.npc_SetupSweeperShields(npc, npc:GetMaxHealth() * 0.1, 15, 8, jcms.factions_GetColorInteger("rebel"))

		-- // Visuals {{{
			npc:SetSubMaterial(0, "models/jcms/ultracopter/body")
			npc:SetSubMaterial(1, "models/jcms/ultracopter/glass")

			local ed = EffectData()
			ed:SetEntity(npc)
			ed:SetScale(0) --Activation time
			util.Effect("jcms_electricarcs", ed)

			local ed = EffectData()
			ed:SetEntity(npc)
			ed:SetScale(0)
			ed:SetStart( Vector(135,0,-15) )
			util.Effect("jcms_burningcharacter", ed)
		-- // }}}
	end,

	think = function(npc, state)
		jcms.npc_Helicopter_Think(npc)	end,

	takeDamage = function(npc, dmg)
		jcms.npc_Helicopter_TakeDamage(npc, dmg)
    end,

	entityFireBullets = function(npc, bulletData)
		bulletData.TracerName = nil
		bulletData.Tracer = math.huge

		bulletData.Callback = function(attacker, tr, dmgInfo)
			local effectdata = EffectData()
			effectdata:SetStart(LerpVector(7/tr.StartPos:Distance(tr.HitPos), tr.StartPos, tr.HitPos))
			effectdata:SetScale(math.random(6500, 9000))
			effectdata:SetAngles(tr.Normal:Angle())
			effectdata:SetOrigin(tr.HitPos)
			effectdata:SetFlags(1)
			util.Effect("jcms_laser", effectdata)

			dmgInfo:SetDamageType( bit.bor(dmgInfo:GetDamageType(), DMG_BURN) )

			if tr.HitWorld and tr.HitNormal:Dot(jcms.vectorUp) > 0 then --Hit world, and not a vertical wall or ceiling.
				local fireCount = #ents.FindByClass("jcms_fire")
				if fireCount < 80 then --Hard-cap at 80, soft-cap at 30.
					local fire = ents.Create("jcms_fire")
					fire:SetPos(tr.HitPos)
					fire:Spawn()

					fire:SetRadius(50)
					fire:SetActivationTime(CurTime() + 5)

					--Gradually reduce dietimes after 30. Goes to roughly 1/3, (around 15s-ish?).
					local dieFac = 1 + math.max(fireCount-30, 0) / 30
					fire.dieTime = CurTime() + 35 / dieFac
				end
			elseif tr.Entity and not tr.Entity:IsOnFire() and not tr.Entity:IsPlayer() then 
				tr.Entity:Ignite(3)
			end
		end

		jcms.npc_Helicopter_FireBullets(npc, bulletData)
	end,

	check = jcms.npc_airCheck
}