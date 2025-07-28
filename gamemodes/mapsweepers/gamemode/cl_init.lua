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

include "sh_bspReader.lua" --Not sure if we even need this data on client. Will include data read-ins if/when necessary. - J

include "shared.lua"
include "sh_debugtools.lua"
include "sh_net.lua"
include "cl_hud.lua"
include "cl_hud_npc.lua"
include "sh_controls.lua"
include "cl_flashlights.lua"
include "cl_terminal.lua"
include "cl_objectives.lua"
include "cl_spawnmenu.lua"
include "cl_offgame.lua"
include "cl_paint.lua"
include "missions/cl_missions.lua"
include "sh_announcer.lua"
include "sh_hints.lua"
include "sh_factions.lua"
include "sh_statistics.lua"
include "cl_codex.lua"
include "npcs/cl_bestiary.lua"
include "cl_addoncompatibility.lua"

-- // Class Includes {{{
	do
		include "classes/sh_classes.lua"
		local classFiles, _ = file.Find( "mapsweepers/gamemode/classes/types/*.lua", "LUA")
		for i, v in ipairs(classFiles) do 
			include("classes/types/" .. v)
		end

		table.sort(jcms.classesOrder, function(first, last)
			local idFirst, idLast = jcms.classesOrderIndices[first] or 10, jcms.classesOrderIndices[last] or 10
			return idFirst < idLast
		end)
	end
-- // }}}

-- // NPC Includes {{{
	do
		--precache files
		local pcacheFiles, _ = file.Find( "mapsweepers/gamemode/npcs/precache/*.lua", "LUA")
		for i, v in ipairs(pcacheFiles) do
			include("npcs/precache/" .. v)
		end 
	end
-- // }}}


if jcms.inTutorial then
	include "cl_tutorial.lua"
end 

--Optimisation. Getting locPly from a lua table is cheaper than the function.
jcms.locPly = jcms.locPly or NULL
hook.Add("InitPostEntity", "jcms_cacheValues", function()
	jcms.locPly = LocalPlayer() -- Optimisation
end)

timer.Create("jcms_locPlySetter", 2, 0, function() -- Sometimes gets unset if other addons break the hook call. This is a bandaid.
	local locPly = LocalPlayer()
	if not IsValid(jcms.locPly) and IsValid(locPly) then
		jcms.locPly = locPly
	end
end)

-- // Fonts {{{

	-- Legal Note:
	-- The font used in the gamemode is IBM Plex Sans. 
	-- However, the files were renamed for OS compatibility reasons.
	-- So we changed the original file names, such as "IBMPlexSans-Regular.ttf", into "jcms_regular". 
	-- The original font software was left intact, as it was provided.
	-- Octantis Addons does not claim copyright over the IBM Plex Sans font.
	-- It is licensed under SIL OPEN FONT LICENSE Version 1.1, and is copyrighted by IBM Corp.
	-- The full text of the license can be read either in the LICENSE_OFL file, or here: https://openfontlicense.org/open-font-license-official-text/

	surface.CreateFont("jcms_hud_superhuge", {
		font = "IBM Plex Sans Light",
		antialias = true,
		extended = true,
		size = 256
	})

	surface.CreateFont("jcms_hud_huge", {
		font = "IBM Plex Sans Light",
		antialias = true,
		extended = true,
		size = 128
	})

	surface.CreateFont("jcms_hud_big", {
		font = "IBM Plex Sans",
		antialias = true,
		extended = true,
		size = 100
	})

	surface.CreateFont("jcms_hud_score", {
		font = "IBM Plex Sans",
		antialias = true,
		extended = true,
		size = 85
	})

	surface.CreateFont("jcms_hud_medium", {
		font = "IBM Plex Sans",
		antialias = true,
		extended = true,
		size = 64
	})

	surface.CreateFont("jcms_hud_small", {
		font = "IBM Plex Sans SemiBold",
		antialias = true,
		extended = true,
		size = 37
	})

	surface.CreateFont("jcms_big", {
		font = "IBM Plex Sans Light",
		antialias = true,
		extended = true,
		size = 32
	})
	
	surface.CreateFont("jcms_medium", {
		font = "IBM Plex Sans SemiBold",
		antialias = true,
		extended = true,
		size = 24
	})
	
	surface.CreateFont("jcms_title", {
		font = "IBM Plex Sans SemiBold",
		antialias = true,
		extended = true,
		size = 18
	})

	surface.CreateFont("jcms_missiondesc", {
		font = "Roboto",
		antialias = true,
		extended = true,
		italic = true,
		size = 18
	})

	surface.CreateFont("jcms_small", {
		font = "Roboto",
		antialias = true,
		extended = true,
		size = 14
	})
	
	surface.CreateFont("jcms_small_bolder", {
		font = "Roboto",
		antialias = true,
		extended = true,
		weight = 1000,
		size = 15
	})

-- // }}}

-- // Faction Colors for my non-jcorp friends {{{

	-- These people get unique colors for their flashlights and HUD, nothing else.
	-- RGG wears purple colors, and Mafia sports golden/yellow colors.
	-- Everyone else has a J Corp theme by default. However, J Corp has several
	-- official members, such as MerekiDor and JonahSoldier.

	-- If you came across this wondering why the special treatment, or what the fuck
	-- is RGG/Mafia, then here's the short version: we've got a gaming friend group with a little
	-- roleplay-like universe with three major factions in it (J Corp, RGG & Mafia), and members
	-- of the private discord server where this gamemode originally came from get some special
	-- colors, since they're not members of J Corp. For immersion.
	
	-- J Corp is a comically evil villain faction (if that wasn't obvious)
	-- RGG is a street gang of desperate gamblers (google "gamblecore")
	-- Mafia is a law enforcement/charity group cuz they genuinely didnt know mafia was supposed to be evil

	-- Yeah, the gamemode is canonically set within that universe of ours. Only we know the truth. 

	jcms.playerfactions_players = {
		-- RGG Members
		["dc4617818bdcc3af96d716ec70b492638cdc075cf5ad7485452f0c798c9e5bcf"] = "rgg", -- traeesen, RGG leader
		["8d992bb020d23a76fb969bc6e93f29cab939c751d2c2637555cb2c87f6233b79"] = "rgg", -- Dullfifqariano, RGG enforcer
		
		-- Mafia Members
		["4f92d868130e272c86a99ad26e3a4f0d920ad58d069aa59ee1b7d98568553a9f"] = "mafia", -- baggie, mafia boss
		["53d0a5fcc6f87fb7449cad422a48196a2c85261598b84354cacea2317077ceb5"] = "mafia", -- Firch, mafia caporegime
		["48f04893f12ffdd62342de3f63664b0c5ac941d0852c61f787c3e1ae3e2e1051"] = "mafia", -- Xelerax, mafia caporegime
		["101449ca879207d041035e8a7c8d07db99dd16aa37626b1a66799084d6ea5594"] = "mafia", -- LeSeiL, mafia soldato
		["adbdc18a436c3d1a1f2544a98351eef55212800855a2d3e0795c2a7d116936c5"] = "mafia"  -- Beaver Eater, mafia soldato
	}

-- // }}}

-- // ConVars {{{

	jcms.cvar_imperial = CreateClientConVar("jcms_imperial", "0", true, false, "If set to 1, distance will be displayed in feet instead of meters")
	jcms.cvar_motionsickness = CreateClientConVar("jcms_motionsickness", "0", true, false, "If set to 1, the HUD won't sway. I'm kinda sorry for you if you have to enable this.")
	jcms.cvar_announcer = CreateClientConVar("jcms_announcer", "1", true, false, "If set to 1, JonahSoldier will watch over your progress with mission control voicelines.")
	jcms.cvar_nomusic = CreateClientConVar("jcms_nomusic", "0", true, false, "Disables mission-start HL2 ambience at the start of each mission")

	jcms.cvar_hud_scale = CreateClientConVar("jcms_hud_scale", "1", true, false, "Scale multiplier for the in-game HUD")
	jcms.cvar_hud_novignette = CreateClientConVar("jcms_hud_novignette", "0", true, false, "Disables the darkening around corners of the screen")
	jcms.cvar_hud_nocolourfilter = CreateClientConVar("jcms_hud_nocolourfilter", "0", true, false, "Disables the colour-modifying screen tint")
	jcms.cvar_hud_noneardeathfilter = CreateClientConVar("jcms_hud_noneardeathfilter", "0", true, false, "Disables the near-death black-and-white effect")

	jcms.cvar_crosshair_style = CreateClientConVar("jcms_crosshair_style", "1", true, false, "0: None\n1: T-shaped\n2: Triangle\n3: Plus-shaped\n4: Circle")
	jcms.cvar_crosshair_dot = CreateClientConVar("jcms_crosshair_dot", "0", true, false, "Enables the central dot on the crosshair")
	jcms.cvar_crosshair_ammo = CreateClientConVar("jcms_crosshair_ammo", "1", true, false, "0: No ammo indicator\n1: Temporary circular\n2: Permanent circular\n3: Temporary numeric\n4: Permanent numeric")

	jcms.cvar_crosshair_width = CreateClientConVar("jcms_crosshair_width", "1", true, false, "Thickness of the crosshair lines")
	jcms.cvar_crosshair_length = CreateClientConVar("jcms_crosshair_length", "17", true, false, "Length of the crosshair lines")
	jcms.cvar_crosshair_gap = CreateClientConVar("jcms_crosshair_gap", "0", true, false, "Added gap to the crosshair (there's a default one of ~8)")

	jcms.cvar_favclass = CreateClientConVar("jcms_favclass", "", true, false, "Will automatically select this class whenever you join a game")

-- // }}}

-- // Hooks {{{

	function GM:RenderScene(v, a, fov)
		if IsValid(jcms.offgame) and not jcms.offgame.allowSceneRender then
			cam.Start2D()
				DisableClipping(false)
				vgui.GetWorldPanel():PaintManual(false)
				jcms.offgame:PaintManual(false)
			cam.End2D()

			return true
		end
	end

	jcms.nextAfkPing = CurTime()
	hook.Add("Think", "jcms_afkPing", function() 
		local cTime = CurTime()
		if jcms.nextAfkPing < cTime then 
			if system.HasFocus() then
				jcms.net_SendAfkPing()
				jcms.nextAfkPing = cTime + 10
			end
		end
	end)

	hook.Add("Think", "jcms_OffgameHandler", function()
		local ply = jcms.locPly
		local obs = ply:GetObserverMode()

		if ( (obs == OBS_MODE_NONE) or (obs == OBS_MODE_CHASE and ply:GetNWInt("jcms_desiredteam", 0) == 2) ) and IsValid(jcms.offgame) and ply:Alive() and not jcms.aftergame then
			jcms.offgame:Remove()
		end
	end)

	hook.Add("Think", "jcms_TerminalCooldown", function()
		local ply = LocalPlayer()

		if not ply:KeyDown(IN_USE) then
			ply.jcms_terminalCooldown = 0
		end
	end)

	jcms.performanceReadings = {}
	jcms.nextPerfReading = CurTime()
	jcms.performanceEstimate = 60
	hook.Add("Think", "jcms_perormancetracker", function() 
		--Track our framrate 10 times per second over 3 seconds, average it, use for disabling certain vfx if perf gets too bad.
		if jcms.nextPerfReading > CurTime() then return end

		if #jcms.performanceReadings > 30 then 
			table.remove(jcms.performanceReadings, 1)
		end

		table.insert(jcms.performanceReadings, RealFrameTime())

		local avgTime = 0
		for i, time in ipairs(jcms.performanceReadings) do 
			avgTime = avgTime + time
		end
		avgTime = avgTime / #jcms.performanceReadings

		jcms.performanceEstimate = 1 / avgTime

		jcms.nextPerfReading = CurTime() + 0.1
	end)

	jcms.cachedValues = {}
	jcms.nextCacheValues = CurTime()
	
	-- // Defaults {{{
		jcms.EyePos_lowAccuracy = EyePos()
		jcms.EyeFwd_lowAccuracy = EyeAngles():Forward() 
		jcms.cachedValues.playerClass = "infantry"

		jcms.cachedValues.crosshair_gap = jcms.cvar_crosshair_gap:GetInt()
		jcms.cachedValues.crosshair_width = jcms.cvar_crosshair_width:GetInt()
		jcms.cachedValues.crosshair_length =jcms.cvar_crosshair_length:GetInt()
		jcms.cachedValues.crosshair_style = jcms.cvar_crosshair_style:GetInt()
		jcms.cachedValues.crosshair_ammo =  jcms.cvar_crosshair_ammo:GetInt()
		jcms.cachedValues.crosshair_dot =  jcms.cvar_crosshair_dot:GetBool()

		jcms.cachedValues.motionSickness = jcms.cvar_motionsickness:GetBool()
		jcms.cachedValues.hudScale = jcms.cvar_hud_scale:GetFloat()
	-- // }}}

	hook.Add("Think", "jcms_cachevalues", function()
		local locPly = jcms.locPly
		
		if not IsValid(locPly) then
			locPly = LocalPlayer()
			jcms.locPly = locPly
		end

		jcms.cachedValues.playerClass = locPly:GetNWString("jcms_class", "infantry")
		jcms.EyePos_lowAccuracy = EyePos() --This doesn't work for things like the 3D2D HUD elements, but is suitable for LOD systems.
		jcms.EyeFwd_lowAccuracy = EyeAngles():Forward() 
	end)
	
	hook.Add("Think", "jcms_cachevalues_slow", function() --Stuff that doesn't change often/that we don't need accuracy for.
		if jcms.nextCacheValues > CurTime() then return end
		local locPly = jcms.locPly

		--There's still some overhead associated with :GetInt, even though we've cached the convar
		--I did this in MW for stuff used ridiculously often.
		--Not sure how big of a deal it'll be here, but I'm running out of things to improve on. 
		jcms.cachedValues.crosshair_gap = jcms.cvar_crosshair_gap:GetInt()
		jcms.cachedValues.crosshair_width = jcms.cvar_crosshair_width:GetInt()
		jcms.cachedValues.crosshair_length =jcms.cvar_crosshair_length:GetInt()
		jcms.cachedValues.crosshair_style = jcms.cvar_crosshair_style:GetInt()
		jcms.cachedValues.crosshair_ammo =  jcms.cvar_crosshair_ammo:GetInt()
		jcms.cachedValues.crosshair_dot =  jcms.cvar_crosshair_dot:GetBool()

		jcms.cachedValues.motionSickness = jcms.cvar_motionsickness:GetBool()
		jcms.cachedValues.hudScale = jcms.cvar_hud_scale:GetFloat()

		jcms.nextCacheValues = CurTime() + 0.25
	end)


	jcms.vm_evacd = jcms.vm_evacd or 0

	function GM:CalcView(ply, origin, angles, fov, znear, zfar)
		angles.roll = 0
		local obs = ply:GetObserverMode() 
		
		if obs == OBS_MODE_CHASE then
			local target = ply:GetObserverTarget()

			if IsValid(target) then
				local jVehicle = target:GetNWEntity("jcms_vehicle")
				if IsValid(jVehicle) and jVehicle.CalcViewDriver then
					return jVehicle:CalcViewDriver(ply, origin, angles, fov, znear, zfar)
				end
			end
		elseif obs == OBS_MODE_NONE then
			jcms.vm_evacd = 0
			local ragdoll = ply:GetRagdollEntity()
			local jVehicle = ply:GetNWEntity("jcms_vehicle")
			local classData = jcms.class_GetLocPlyData()
			
			if IsValid(ragdoll) then
				local boneId = ragdoll:LookupBone("ValveBiped.Bip01_Head1")
				local attachmentId = ragdoll:LookupAttachment("eyes")

				if attachmentId > 0 then
					local angpos = ragdoll:GetAttachment(attachmentId)

					if boneId then
						ragdoll:ManipulateBoneScale(boneId, vector_origin)
					end

					local view = {
						origin = angpos.Pos,
						angles = angpos.Ang,
						fov = fov + math.sin( CurTime() ),
						drawviewer = false,
						znear = 0.01,
						zfar = 100000
					}
				
					return view
				else
					if boneId then
						ragdoll:ManipulateBoneScale(boneId, Vector(1,1,1))
					end
				end
			elseif jcms.hud_beginsequencet <= jcms.hud_beginsequenceLen then
				local f = math.Clamp(math.Remap(jcms.hud_beginsequencet, 0.3, 3.5, 1, 0), 0, 1)
				
				local val = Lerp(f^8, 64, 0)
				local cos, sin = math.sin(val) + math.Rand(-0.1, 0.1), math.cos(val) + math.Rand(-0.1, 0.1)
				
				angles.p = angles.p + cos*f*f
				angles.y = angles.y + sin*f*f
				
				local view = {
					origin = origin,
					angles = angles,
					fov = Lerp(f^3, fov, 150),
					drawviewer = false,
					znear = znear,
					zfar = zfar
				}
				
				return view
			elseif IsValid(jVehicle) and jVehicle.CalcViewDriver then
				return jVehicle:CalcViewDriver(ply, origin, angles, fov, znear, zfar)
			elseif classData and classData.CalcView then
				return classData.CalcView(ply, origin, angles, fov, znear, zfar)
			end
			
			local wep = ply:GetActiveWeapon()
			if IsValid(wep) and wep.CalcView then
				origin, angles, fov = wep:CalcView(ply, origin, angles, fov)
			end

			return { origin = origin, angles = angles, fov = fov, znear = znear, zfar = zfar }
		elseif obs == OBS_MODE_ROAMING then
			-- Evacuated
			local evactime = jcms.vm_evacd or 0
			
			local time = CurTime()
			local timefrac = math.ease.InOutQuart(math.Clamp(math.TimeFraction(0, 5.0, evactime), 0, 1))
			local timefrac2 = math.ease.InOutQuart(math.Clamp(math.TimeFraction(0, 5.0, evactime), 0, 1))
			local timefrac3 = 1 - 1/(evactime+1)
			local timefrac4 = evactime > 2 and math.min(1, math.Remap(evactime, 2, 5, 0, 1)) or 0
			
			angles = ply:EyeAngles()
			local fwd, right, up = angles:Forward(), angles:Right(), angles:Up()
			
			origin:Add(fwd*(-Lerp(timefrac3, 64, 180)-evactime*2))
			origin:Add(up*(Lerp(timefrac3, 24, 42)+evactime))
			origin:Add(right*evactime)
			angles.p = Lerp(timefrac, angles.p, -89)
			angles:RotateAroundAxis(up, Lerp(timefrac2, 0, 10))
			
			angles:RotateAroundAxis(angles:Up(), timefrac4 * math.sin(time*4)*2)
			angles:RotateAroundAxis(angles:Right(), timefrac4 * math.cos(time*4+1)*3)
			
			local view = {
				origin = origin,
				angles = angles,
				fov = Lerp(timefrac2, fov+evactime*0.5, fov*0.75),
				drawviewer = false,
				znear = znear,
				zfar = zfar
			}
			
			jcms.vm_evacd = evactime + FrameTime()
			return view
		else
			jcms.vm_evacd = 0
		end
	end

	hook.Add("CalcViewModelView", "jcms_ViewModelView", function( wep, viewModel, oldPos, oldAng, cPos, cAng )
		local owner = viewModel:GetOwner()
		if not IsValid(owner) or not owner:IsPlayer() or not(owner:GetObserverMode() == OBS_MODE_NONE) then return end
		local classData = jcms.class_GetData(owner)
		if classData and classData.CalcViewModelView then 
			return classData.CalcViewModelView(wep, viewModel, oldPos, oldAng, cPos, cAng, owner)
		end
	end)
	
	jcms.render_matRing = Material("effects/select_ring")

	jcms.render_matShield = Material("models/effects/vortshield")
	if jcms.render_matShield:IsError() then -- If we don't have EP2 for the vort shield, use a fallback material
		jcms.render_matShield = Material("effects/tvscreen_noise002a")
	end

	local emt = FindMetaTable("Entity")
	local nmt = FindMetaTable("NPC")

	local function drawSweeperShield(ent)
		local swpShield = emt.GetNWInt(ent, "jcms_sweeperShield", -1)
		if swpShield >= 0 then
			local maxShield = emt.GetNWInt(ent, "jcms_sweeperShield_max", -1)
			local r, g, b = jcms.util_ColorFromIntegerUnpacked( emt.GetNWInt(ent, "jcms_sweeperShield_colour", 255) )
			local alpha = math.Clamp(swpShield/maxShield, 0, 1)
			
			render.SetColorModulation((r/200) * alpha, (g/200) * alpha, (b/200) * alpha)
			render.MaterialOverride(jcms.render_matShield)
			cam.Start3D()
				emt.DrawModel(ent)
			cam.End3D()
			render.MaterialOverride()
			render.SetColorModulation(1, 1, 1)
		end
	end


	hook.Add("PostDrawOpaqueRenderables", "jcms_BulletShields", function(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
		if bDrawingDepth or bDrawingSkybox or isDraw3DSkybox or render.GetRenderTarget() then return end

		local time = CurTime()*8
		local vUp = jcms.vectorUp
		local matRing = jcms.render_matRing

		for i, ent in ipairs( ents.FindByClass("npc_*") ) do
			if IsValid(ent) and not emt.GetNoDraw(ent) and not emt.IsDormant(ent) then
				local shield = emt.GetNWInt(ent, "jcms_shield", 0)
				if shield > 0 then
					local entTbl = ent:GetTable()

					if not entTbl.jcms_shieldDamageAnim then
						entTbl.jcms_shieldDamageAnim = 0
						entTbl.jcms_shieldLastCount = shield
					elseif entTbl.jcms_shieldLastCount ~= shield then
						entTbl.jcms_shieldDamageAnim = 1
						entTbl.jcms_shieldLastCount = shield
					else
						entTbl.jcms_shieldDamageAnim = math.max(0, entTbl.jcms_shieldDamageAnim - FrameTime() * 4)
					end
					local damageAnim = entTbl.jcms_shieldDamageAnim
					render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )

						local pos, rad = ent:WorldSpaceCenter(), ent:BoundingRadius()
						local osc = math.sin(time+i)
						local size = rad*2.4*(1-osc^2) + damageAnim * 50
						render.SetColorMaterial()
						local alpha = shield * 8
						--todo: we might be able to save time by storing these color objects on the entity & adjusting their components here instead.
						render.DrawSphere(pos, rad - math.random()*4, 6, 6, Color(255, 200, 100*damageAnim, alpha+150*damageAnim) )
						render.SetMaterial(jcms.render_matRing)
						render.DrawQuadEasy(pos + osc*rad*1.1*vUp, vUp, size, size, Color(255, 255, damageAnim*255), 0)
						
						osc = math.sin(time+i+0.6)
						size = rad*2.7*(1-osc^2)
						render.DrawQuadEasy(pos + osc*rad*1.2*vUp, vUp, size, size, Color(255, 140+150*damageAnim, 175*damageAnim, 150), 0)
						
					render.OverrideBlend( false )
				end
				
				drawSweeperShield(ent)
			else
				local entTbl = ent:GetTable()
				entTbl.jcms_shieldDamageAnim = nil
				entTbl.jcms_shieldLastCount = nil
			end
		end

		for i, ent in ipairs(ents.FindByClass("jcms_turret")) do 
			if IsValid(ent) and not emt.IsDormant(ent) then
				drawSweeperShield(ent)
			end
		end
	end)

	local function drawLiabilityText(ffKills)
		local liabilityTxt = string.format("%s: x%d", language.GetPhrase("jcms.liability"), ffKills)
		draw.SimpleText(liabilityTxt, "jcms_hud_big", 0, 0, jcms.color_dark, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("↓", "jcms_hud_big", 0, 15, jcms.color_dark, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

		render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )
			draw.SimpleText(liabilityTxt, "jcms_hud_big", -ffKills*math.random()/4 -2, -ffKills*math.random()/4 -2, jcms.color_bright, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)	
			draw.SimpleText("↓", "jcms_hud_big", -ffKills*math.random()/4 -2, 15 -ffKills*math.random()/4 -2, jcms.color_bright, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		render.OverrideBlend(false)

		--TODO: Friendly-fire icon
	end

	hook.Add("PostDrawOpaqueRenderables", "jcms_friendlyfire_counter", function(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
		if bDrawingDepth or bDrawingSkybox or isDraw3DSkybox or render.GetRenderTarget() then return end

		local cTime = CurTime()
		local addVec = Vector(0,0,105)
		for i, ply in player.Iterator() do
			if not IsValid(ply) or ply:IsDormant() or ply:GetNoDraw() or not(ply:GetObserverMode() == OBS_MODE_NONE) then continue end

			local ffKills = ply:GetNWInt("jcms_friendlyfire_counter", 0)
			if ffKills < 5 then continue end


			local pos = ply:GetPos()
			addVec.z = 105 + math.sin(cTime*2 + ply:EntIndex() * 2) * 10
			pos:Add(addVec)
			cam.Start3D2D( pos, Angle(0,cTime * 75,90), 0.25 )
				drawLiabilityText(ffKills)
			cam.End3D2D()
			
			cam.Start3D2D( pos, Angle(0,cTime * 75 - 180,90), 0.25 )
				drawLiabilityText(ffKills)
			cam.End3D2D()
		end
	end)
	
	hook.Add("TranslateActivity", "jcms_ClassAnimReplace", function(ply, act)
		local data = jcms.class_GetData(ply)
		if data and data.TranslateActivity then
			return data.TranslateActivity(ply, act)
		end
	end)
	
	hook.Add("PreDrawOpaqueRenderables", "jcms_ExtraHUD", function(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
		if bDrawingDepth or bDrawingSkybox or isDraw3DSkybox then return end

		local locPly = jcms.locPly
		local data = jcms.class_GetData(locPly)
		if data and data.PreDrawOpaqueRenderables then
			data.PreDrawOpaqueRenderables(locPly)
		end
	end)

	hook.Add("StartCommand", "jcms_MouseWheelTracker", function(ply, cmd)
		--if ply == LocalPlayer() then
		if ply == jcms.locPly then 
			local frameIndex = FrameNumber() % 600
			if frameIndex ~= jcms.mousewheelLastIndex or cmd:GetMouseWheel() ~= 0 then
				if frameIndex ~= jcms.mousewheelLastIndex then
					jcms.mousewheelOccupied = false
				end
				
				jcms.mousewheelLastIndex = frameIndex
				jcms.mousewheel = cmd:GetMouseWheel()
			end
		end
	end)

	local function jcms_lod_renderOverride(self, flags) --Weapon LOD
		if self:WorldSpaceCenter():DistToSqr(jcms.EyePos_lowAccuracy) < 1750^2 then 
			self:DrawModel(flags)
		end
	end

	hook.Add("NetworkEntityCreated", "jcms_lod_setup", function(ent) 
		if ent:IsWeapon() and not(ent:GetOwner() == LocalPlayer()) and not ent:IsScripted() then 
			ent.RenderOverride = jcms_lod_renderOverride
		end
	end)

	hook.Add( "CreateClientsideRagdoll", "jcms_ragdoll_fastclear", function(ent, ragdoll)
		timer.Simple(50, function()
			if not IsValid(ragdoll) or not ragdoll:GetClass() == "class C_ClientRagdoll" then return end
			
			local ed = EffectData()
			ed:SetColor(jcms.util_colorIntegerJCorp) --Would be nice to be faction-coloured, but client doesn't know what faction npcs are.
			ed:SetFlags(3)
			ed:SetEntity(ragdoll)
			util.Effect("jcms_spawneffect", ed)

			timer.Simple(2, function()
				if not IsValid(ragdoll) then return end 

				ragdoll:Remove()
			end)
		end)
	end)

-- // }}}

-- // Misc {{{

	function jcms.playRandomSong()
		local songs = {
			"ambient/levels/citadel/citadel_hub_ambience1.mp3",
			"music/stingers/hl1_stinger_song27.mp3",
			"music/hl1_song24.mp3", -- Singularity
			"music/hl1_song21.mp3", -- Dirac Shore
			"music/hl1_song20.mp3", -- Escape Array
			"music/hl1_song19.mp3", -- Negative Pressure
			"music/hl1_song14.mp3", -- Triple Entanglement
			"music/hl1_song17.mp3", -- Tau-9
			"music/hl1_song3.mp3", -- Black Mesa Inbound
			"music/hl1_song5.mp3", -- Echoes of a Resonance Cascade
			"music/hl2_song7.mp3", -- Ravenholm Reprise
			"music/hl2_song8.mp3", -- Highway 17
			"music/hl2_song10.mp3", -- A Red Letter Day
			"music/hl2_song19.mp3", -- Nova Prospekt
			"music/hl2_song26.mp3", -- Our Resurrected Teleport
			"music/hl2_song26_trainstation1.mp3", -- Train Station 1
			"music/hl2_song27_trainstation2.mp3", -- Train Station 2
			"music/hl2_song30.mp3", -- Calabi-Yau Model
			"music/hl2_song33.mp3" -- Probably Not a Problem
		}
		
		if IsMounted("episodic") then
			-- EP1 songs
			table.Add(songs, {
				"music/vlvx_song2.mp3", -- Combine Advisory
				"music/vlvx_song4.mp3" -- Guard Down
			})
		end
		
		if IsMounted("ep2") then
			-- EP2 songs
			table.Add(songs, {
				"music/vlvx_song0.mp3", -- No One Rides For Free
				"music/vlvx_song9.mp3", -- Crawl Yard
				"music/vlvx_song26.mp3", -- Inhuman Frequency
				"music/vlvx_song20.mp3" -- Extinction Event Horizon
			})
		end
		
		EmitSound(songs[math.random(1, #songs)], EyePos(), -2, CHAN_AUTO, 1, 75)
	end

-- // }}}

-- // Drawing {{{

	function jcms.draw_Circle(x, y, w, h, thickness, segments, fromAngle, toAngle)
		fromAngle = fromAngle or 0
		toAngle = toAngle or math.pi*2
		fromAngle, toAngle = math.min(fromAngle, toAngle), math.max(fromAngle, toAngle)
		
		draw.NoTexture()
		--x = x + w/2
		--y = y + h/2
		segments = math.min(segments, 100)
		for i=0, segments do
			local a1 = math.Remap(i, 0, segments+1, fromAngle, toAngle)
			local a2 = math.Remap(i+1, 0, segments+1, fromAngle, toAngle)
			local cos1, sin1 = math.cos(a1), math.sin(a1)
			local cos2, sin2 = math.cos(a2), math.sin(a2)
			local vtx = {
				{ x = x + cos1*w, y = y + sin1*h },
				{ x = x + cos2*w, y = y + sin2*h },
				{ x = x + cos2*(w-thickness), y = y + sin2*(h-thickness) },
				{ x = x + cos1*(w-thickness), y = y + sin1*(h-thickness) }
			}

			surface.DrawPoly(vtx)
		end
	end

	function jcms.draw_IconCash(font, x, y, borderThickness)
		surface.SetFont(font)
		local tw, th = surface.GetTextSize("J")
		local max = (math.max(tw, th) + 2)*0.6
		surface.SetTextColor( surface.GetDrawColor() )
		jcms.draw_Circle(x, y, max, max, borderThickness, 12)
		surface.SetTextPos(x - tw/2, y - th/2)
		surface.DrawText("J")
	end

	do --cheaper version for the hud-J
		local coin_rt = GetRenderTarget( "jcms_coin_rt", 24*2, 24*2)

		render.PushRenderTarget( coin_rt )
			cam.Start2D()
				render.Clear( 0,0,0,0) --give us alpha, we start black.

				surface.SetFont("jcms_hud_small")
				surface.SetTextColor(255, 255, 255, 255) --white, so we can set it ourselves later.
				surface.SetDrawColor(255, 255, 255, 255 ) --ditto
			
				jcms.draw_Circle(24, 24, 24, 24, 4, 12)
				
				surface.SetTextPos(24 - 16/2, 24 - 37/2)
				surface.DrawText("J")
			cam.End2D()
		render.PopRenderTarget()
		
		local coin_mat = CreateMaterial( "jcms_coin_mat", "UnlitGeneric", {
			["$basetexture"] = coin_rt:GetName(),
			["$translucent"] = 1,
			["$vertexcolor"] = 1,
			["$vertexalpha"] = 1
		} )
		
		function jcms.draw_IconCash_optimised(x, y)
			surface.SetMaterial(coin_mat)
			surface.DrawTexturedRect(x - 24, y - 24, 24*2, 24*2)
		end
	end

-- // }}}

-- // Other rendering {{{

	jcms.gunMats = jcms.gunMats or {}

	jcms.render_rebelHackBeamMat = Material("effects/laser_citadel1")
	jcms.render_rebelHackBeamColors = {
		Color(230, 100, 255),
		Color(220, 180, 255),
		Color(183, 64, 255),
		Color(32, 0, 255)
	}

	jcms.mat_circle = CreateMaterial( "jcms_portal_lod", "UnlitGeneric", {
		["$basetexture"] = "shadertest/spheremask",
		["$translucent"] = 1,
		["$vertexalpha"] = 1,
		["$vertexcolor"] = 1,
		["$alphatest"] = 1
	} )

	function jcms.render_HackedByRebels(ent)
		local entPos = ent:GetPos()
		local eyeDist = jcms.EyePos_lowAccuracy:Distance(entPos)
		if eyeDist > 4500 then return end
		
		render.SetMaterial(jcms.render_rebelHackBeamMat)
		local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
		local minsX, minsY, minsZ = mins:Unpack()
		local maxsX, maxsY, maxsZ = maxs:Unpack()

		local norm = VectorRand(-1, 1)
		norm:Normalize()
		local right = norm:Cross(jcms.vectorUp)
		
		local gi = 0
		local cols = jcms.render_rebelHackBeamColors
		local beamReduction = math.floor(math.min(3, eyeDist/1500)) --LOD
		for i=1, math.random(0, 3 - beamReduction ) do
			v = Vector(math.Rand(minsX, maxsX), math.Rand(minsY, maxsY), math.Rand(minsZ, maxsZ))
			v:Add(entPos)
		
			local n = math.random(4, 6)
			render.StartBeam(n)
			local size = math.Rand(4, 16) * (beamReduction/3 + 1)
			for j=1, n do
				gi = gi +1
				local f = math.Remap(j, 1, n, 0, 1)
				local a = f*math.pi*2
				local cos, sin = (math.cos(a)+1.01)*size, (math.sin(a)+1.01)*size
				right:Mul(cos)
				norm:Mul(sin)
				v:Add(right)
				v:Add(norm)
				render.AddBeam(v, 24/i, f*0.6+0.2, cols[gi % #cols + 1] )
				v:Sub(norm)
				v:Sub(right)
				norm:Div(sin)
				right:Div(cos)
			end
			render.EndBeam()

			norm:SetUnpacked(math.Rand(-1, 1), math.Rand(-1, 1), math.Rand(-1, 1))
			norm:Normalize()
			right = norm:Cross(jcms.vectorUp)
		end
	end
	
	hook.Add("PostPlayerDraw", "jcms_classDraw", function(ply, flags)
		local classData = jcms.class_GetData(ply)
		if classData and classData.Render then
			classData.Render(ply, flags)
		end
	end)

-- // }}}

-- // Util {{{

	function jcms.util_GetRealFOV()
		local frame = FrameNumber()
		if (not jcms.cachedValues.fov) or (frame > jcms.cachedValues.fov_frame) then
			jcms.cachedValues.fov_frame = frame
			
			local v1 = gui.ScreenToVector(0, ScrH()/2)
			local v2 = gui.ScreenToVector(ScrW(), ScrH()/2)

			jcms.cachedValues.fov = math.deg( math.acos( v1:Dot(v2) ) )
		end

		return jcms.cachedValues.fov
	end

	function jcms.util_ShortEyeTrace(ply, distance, mask)
		local pos = ply:EyePos()
		local fwd = ply:EyeAngles():Forward()
		fwd:Mul(distance or 256)
		return util.TraceLine { start = pos, endpos = pos + fwd, filter = jcms.locPly, mask = mask }
	end

-- // }}}

-- // Color Modification {{{

	jcms.colormod = {
		[ "$pp_colour_addr" ] = 0,
		[ "$pp_colour_addg" ] = 0,
		[ "$pp_colour_addb" ] = 0,
		[ "$pp_colour_mulr" ] = 0,
		[ "$pp_colour_mulg" ] = 0,
		[ "$pp_colour_mulb" ] = 0,
		[ "$pp_colour_contrast" ] = 1.06,
		[ "$pp_colour_brightness" ] = 0.025,
		[ "$pp_colour_colour" ] = 1,
	}

	jcms.colormod_death = 0

	hook.Add("RenderScreenspaceEffects", "jcms_jvision", function()
		local colourmod = not jcms.cvar_hud_nocolourfilter:GetBool()
		local deathmod = not jcms.cvar_hud_noneardeathfilter:GetBool()

		local me = jcms.locPly
		local classData = jcms.class_GetLocPlyData()

		local cTime = CurTime()
		
		if colourmod then
			if classData and classData.ColorMod then
				classData.ColorMod(me, jcms.colormod)
			else
				local color = jcms.color_bright
				local avg = (color.r + color.g + color.b) / 3

				local addFactor, mulFactor = (math.sin(cTime) + 1)/2 * 0.03 + 0.08, (math.cos(cTime) + 1)/2 * 0.05
				
				local blind = 0
				local red = math.Clamp(jcms.hud_blindingRedLight or 0, -1, 1)
				if red > 0 then
					jcms.hud_blindingRedLight = math.max(0, red - FrameTime())
					blind = math.ease.InCubic(red)
				elseif red < 0 then
					jcms.hud_blindingRedLight = math.min(0, red + FrameTime())
					blind = -math.ease.InCubic(-red)
				end
				
				jcms.colormod["$pp_colour_addr"] = (color.r - avg) / 255 * addFactor
				jcms.colormod["$pp_colour_addg"] = (color.g - avg) / 255 * addFactor - blind*0.3
				jcms.colormod["$pp_colour_addb"] = (color.b - avg) / 255 * addFactor - blind*0.3

				jcms.colormod["$pp_colour_mulr"] = (color.r - avg) / 255 * mulFactor
				jcms.colormod["$pp_colour_mulg"] = (color.g - avg) / 255 * mulFactor
				jcms.colormod["$pp_colour_mulb"] = (color.b - avg) / 255 * mulFactor
				
				jcms.colormod["$pp_colour_contrast"] = Lerp(blind^2, 1.06, math.Rand(2.7, 3.06))
				jcms.colormod["$pp_colour_brightness"] = Lerp(blind^2, 0.025, -math.Rand(0.67, 0.72))
			end
		else
			jcms.colormod["$pp_colour_addr"] = 0
			jcms.colormod["$pp_colour_addg"] = 0
			jcms.colormod["$pp_colour_addb"] = 0

			jcms.colormod["$pp_colour_mulr"] = 0
			jcms.colormod["$pp_colour_mulg"] = 0
			jcms.colormod["$pp_colour_mulb"] = 0

			jcms.colormod["$pp_colour_contrast"] = 1
			jcms.colormod["$pp_colour_brightness"] = 0
		end

		if IsValid(me) and me:GetObserverMode() == OBS_MODE_NONE and deathmod then
			local W = 15
			local maxArmour = me:GetMaxArmor()
			jcms.colormod_death = (jcms.colormod_death*W + 1-math.Clamp( math.max(me:Health()/me:GetMaxHealth(), maxArmour>0 and ((me:Armor()/maxArmour)^2)/2 or 0), 0, 1))/(W+1)
			jcms.colormod[ "$pp_colour_colour" ] = Lerp(jcms.colormod_death^3, 1, math.sin( cTime*2 )*0.05)
		else
			jcms.colormod_death = 0
			jcms.colormod[ "$pp_colour_colour" ] = 1
		end
		
		DrawColorModify(jcms.colormod)
	end)

-- // }}}

-- // Fog {{{
	--add your data to the fogStack in PreDrawSkyBox
	jcms.fogStack = {}
	jcms.mapFog = {
		fogCol = color_white,
		fogStart = 0,
		fogEnd = 0,
		fogIntensity = 0
	} --Map fog for blending

	function jcms.fogStack_push(data)
		table.insert(jcms.fogStack, data)
	end

	local function jcms_fog(scale)
		if #jcms.fogStack == 0 then return end 
		scale = scale or 1 

		-- // Blending {{{
			local r, g, b = 0, 0, 0
			local fogMaxDensity = 0
			local fogStart, fogEnd = 0, 0

			local totalIntensity = 0
			for i, fogData in ipairs(jcms.fogStack) do 
				totalIntensity = totalIntensity + fogData.fogMaxDensity
			end

			for i, fogData in ipairs(jcms.fogStack) do 
				local frac = fogData.fogMaxDensity / totalIntensity

				local fr, fg, fb = fogData.fogCol:Unpack()
				r, g, b = r + (fr / 255) * frac, g + (fg / 255) * frac, b + (fb / 255) * frac 
				fogMaxDensity = fogMaxDensity + fogData.fogMaxDensity * frac
				fogStart = fogStart + fogData.fogStart * frac 
				fogEnd = fogEnd + fogData.fogEnd * frac
			end
		-- // }}}

		-- // {{{ Smooth transition from map-fog. 
			local f = 1 - fogMaxDensity
			local mr, mg, mb = jcms.mapFog.fogCol:Unpack()
			r, g, b = Lerp(f, r, mr/255), Lerp(f, g, mg/255), Lerp(f, b, mb/255)
			fogStart, fogEnd = Lerp(f, fogStart, jcms.mapFog.fogStart), Lerp(f, fogEnd, jcms.mapFog.fogEnd)
			fogMaxDensity = Lerp(f, fogMaxDensity, jcms.mapFog.fogIntensity)
		-- // }}}

		render.FogColor(r*255, g*255, b*255)
		render.FogMaxDensity(fogMaxDensity)
		render.FogMode(MATERIAL_FOG_LINEAR)
		
		render.FogStart(fogStart * scale)
		render.FogEnd(fogEnd * scale)

		return true
	end

	hook.Add("PostDraw2DSkyBox", "jcms_fog", function() --Mimic fog effect on the sky
		if #jcms.fogStack == 0 then return end 
		
		local fogCol
		local fogMaxDensity = 0

		local totalIntensity = 0
		for i, fogData in ipairs(jcms.fogStack) do
			totalIntensity = totalIntensity + fogData.fogMaxDensity
		end

		local r, g, b = 0, 0, 0
		for i, fogData in ipairs(jcms.fogStack) do 
			local frac = fogData.fogMaxDensity / totalIntensity
			
			local fr, fg, fb = fogData.fogCol:Unpack()
			r, g, b = r + (fr / 255) * frac, g + (fg / 255) * frac, b + (fb / 255) * frac 

			fogMaxDensity = fogMaxDensity + fogData.fogMaxDensity * frac
		end

		fogCol = Color(r, g, b)
		render.SetColorMaterial()
		render.DrawSphere( EyePos(), -1000, 10, 10, Color(fogCol.r, fogCol.g, fogCol.b, fogMaxDensity * 255) )
	end)

	hook.Add("SetupWorldFog", "jcms_fog", jcms_fog)

	hook.Add("SetupSkyboxFog", "jcms_fog", jcms_fog)

	hook.Add("PostRender", "jcms_postFog", function()
		jcms.fogStack = {} --Clear the table. Anyone using us will have to push again next time.
	end)
-- // }}}

-- // Weapons {{{

	jcms.weapon_prices = jcms.weapon_prices or {}
	jcms.weapon_loadout = jcms.weapon_loadout or {}
	jcms.weapon_favourites = jcms.weapon_favourites or {}

-- // }}}

-- // Skybox {{{

	do
		local mat_beam = Material "sprites/physbeama.vmt"
		local mat_lamp = Material "effects/lamp_beam.vmt"
		local skyPods = {}
		local skyPodsTotal = 30
		local fallNormal = math.random() < 0.2 and Vector(math.Rand(-2, 2), math.Rand(-2, 2), math.Rand(-4, -3)) or Vector(math.random()-0.5, math.random()-0.5, -1-math.random()*2)
		fallNormal:Normalize()
		
		local function makeSkyPod()
			local skypod = {}
			
			local a = math.random()*math.pi*2
			local cos, sin = math.cos(a), math.sin(a)
			local dist = 1000 * ( math.Rand(0.8, 1.8)^3 )
			local altitude = math.Rand(1000, 5000)
			
			skypod.pos = Vector(cos*dist, sin*dist, 0) - fallNormal*altitude
			skypod.fade = 0
			skypod.speed = math.Rand(54, 70)
			
			return skypod
		end
		
		local droppodCol = Color(255, 30, 30)
		local droppodColBrighter = Color(255, 130, 120)
		hook.Add("PostDraw2DSkyBox", "jcms_Skybox", function()
			if jcms.performanceEstimate < 45 or render.GetRenderTarget() then return end

			render.OverrideDepthEnable( true, false )

			if #skyPods < skyPodsTotal then
				for i=#skyPods+1, skyPodsTotal do
					skyPods[i] = makeSkyPod()
				end
			end
			
			cam.Start3D(Vector(0, 0, 0))
				local col = droppodCol
				local colBrighter = droppodColBrighter
				local respawnThreshold = -512
				
				render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD)
				local dt = FrameTime()
				local time = CurTime()
				for i, skypod in ipairs(skyPods) do
					local f = skypod.fade
					if skypod.pos.z > respawnThreshold then
						skypod.fade = math.min(1, skypod.fade + dt)
						skypod.pos:Add(fallNormal * (skypod.speed * dt))
						
						render.SetMaterial(mat_beam)
						render.StartBeam(2)
							render.AddBeam(skypod.pos, math.Rand(3, 7)*f, 0, colBrighter)
							render.AddBeam(skypod.pos - fallNormal*math.random(64, 100), 0, 1, col)
						render.EndBeam()
						
						render.SetMaterial(mat_lamp)
						render.StartBeam(2)
							local width = math.Rand(12, 24)*f
							render.AddBeam(skypod.pos, width, 0, colBrighter)
							render.AddBeam(skypod.pos - fallNormal*math.random(64, 100), width, 1, col)
						render.EndBeam()
					else
						skypod.fade = math.max(0, skypod.fade - dt/2)
						
						if skypod.fade <= 0 then
							table.Empty(skypod)
							skyPods[i] = makeSkyPod()
						end
					end
				end
				render.OverrideBlend(false)
			cam.End3D()
			
			render.OverrideDepthEnable( false, false )
		end)
	end

-- // }}}

-- // Chat {{{

	jcms.chatHistory = jcms.chatHistory or {}
	jcms.chatHistoryLength = jcms.chatHistoryLength or 512
	jcms.chatHistoryI = jcms.chatHistoryI or 1

	function jcms.chatHistory_Add(plyName, text, type)
		local t = jcms.chatHistory[ jcms.chatHistoryI ]
		jcms.chatHistory[ jcms.chatHistoryI ] = { plyName, text, type }
		jcms.chatHistoryI = (jcms.chatHistoryI % jcms.chatHistoryLength) + 1
	end

	function jcms.chatHistory_Iterator()
		local i = 0
		if #jcms.chatHistory >= jcms.chatHistoryLength then
			return function()
				i = i + 1
				local ri = (jcms.chatHistoryI + i - 2) % jcms.chatHistoryLength + 1

				if jcms.chatHistory[ri] and i <= jcms.chatHistoryLength then
					return i, ri, jcms.chatHistory[ri]
				end
			end
		else
			return function()
				i = i + 1

				if jcms.chatHistory[i] and i <= #jcms.chatHistory then
					return i, i, jcms.chatHistory[i]
				end
			end
		end
	end

	hook.Add("ChatText", "jcms_trackChatHistory", function(plyIndex, plyName, text, type)
		jcms.chatHistory_Add(plyName, text, type)
	end)

	hook.Add("OnPlayerChat", "jcms_trackChatHistory", function(ply, text, teamChat, isDead)
		if not IsValid(ply) or not ply:IsPlayer() then return end 

		jcms.chatHistory_Add(ply:Nick(), text, "chat")
	end)

-- // }}}

-- // Filesystem {{{
	file.CreateDir("mapsweepers")
	file.CreateDir("mapsweepers/client")
	gameevent.Listen("client_disconnect")

	do --Statistics.
		local statsFile = "mapsweepers/client/stats.dat"
		hook.Add("InitPostEntity", "jcms_restoreStats", function()
			if file.Exists(statsFile, "DATA") then
				local dataTxt = file.Read(statsFile, "DATA")
				local dataTbl = util.JSONToTable(util.Decompress(dataTxt))

				jcms.statistics = dataTbl or jcms.statistics --fallback for if our file's fucked.
				if not dataTbl then
					jcms.debug_fileLog("Failed to read stats file. Stats reset.")
					Error("[Map Sweepers] Failed to read stats file. Stats reset.")
				end
			end
		end)

		local function storeStats()
			local dataStr = util.Compress( util.TableToJSON(jcms.statistics) )
			file.Write(statsFile, dataStr)
		end

		hook.Add("client_disconnect", "jcms_storeStats", storeStats)
		hook.Add("ShutDown", "jcms_storeStats", storeStats) -- Server changing levels doesn't call client_disconnect
	end

	do -- Favourite weapons.
		local favsFile = "mapsweepers/client/fav_weapons.txt"
		hook.Add("InitPostEntity", "jcms_restoreFavWeapons", function()
			if file.Exists(favsFile, "DATA") then
				local dataTxt = file.Read(favsFile, "DATA")
				local entries = string.Split(dataTxt, ",")

				for i, entry in ipairs(entries) do
					local trimmed = string.Trim( tostring(entry) )
					jcms.weapon_favourites[ trimmed ] = true
				end
			end
		end)

		local function storeFavWeapons()
			local favWeapons = {}
			for k, v in pairs(jcms.weapon_favourites) do 
				if v then
					table.insert(favWeapons, k)
				end
			end
			local dataStr = #favWeapons > 0 and table.concat(favWeapons, ", ") or ""
			file.Write(favsFile, dataStr)
		end

		hook.Add("client_disconnect", "jcms_storeFavWeapons", storeFavWeapons)
		hook.Add("ShutDown", "jcms_storeFavWeapons", storeFavWeapons)
	end
-- // }}}

-- // Post {{{

	hook.Run("MapSweepersReady") -- If you want to make an addon that adds new content into Map Sweepers, use this hook.

-- // }}}
