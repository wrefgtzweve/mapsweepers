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
AddCSLuaFile()

ENT.Type = "ai"
ENT.Base = "base_anim"
ENT.PrintName = "Zombie Beacon"
ENT.Author = "Octantis Addons"
ENT.Category = "Map Sweepers"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

jcms.team_jCorpClasses["jcms_zombiebeacon"] = true

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "IsComplete")
	self:NetworkVar("Bool", 1, "Active")
	
	self:NetworkVar("Float", 0, "Charge")
	self:NetworkVar("Float", 1, "HealthFraction")
	if SERVER then 
		self:SetCharge(0)
		self:SetHealthFraction(1)
	end
end

if SERVER then 
	function ENT:Initialize()
		self:SetModel("models/jcms/jcorp_nuke.mdl")
		self:PhysicsInitStatic(SOLID_VPHYSICS)

		self:SetMaxHealth(3000)
		self:SetHealth(self:GetMaxHealth())
		
		jcms.terminal_Setup(self, "jcorpnuke", "jcorp")
		self:SetNWBool("jcms_terminal_locked", false)
		self:SetNWString("jcms_terminal_modeData", "1")
		self.jcms_hackType = nil

		self:AddFlags( FL_NOTARGET )
		
		local pos, ang = self:WorldSpaceCenter(), self:GetAngles()
		self.bullseyes = {}
		for i=1, 8, 1 do 
			local ent = ents.Create("jcms_bullseye")

			local nPos, nAng = Vector(pos), Angle(ang)
			nAng:RotateAroundAxis(nAng:Up(), 45 * (i-1))
			nPos:Add(nAng:Forward()*75) --75
			
			debugoverlay.Cross(nPos, 30, 15, Color( 0, 0, 0 ), true)
			ent:SetPos(nPos)
			ent:Spawn()
			ent.DamageTarget = self

			ent:AddFlags(FL_NOTARGET)
			--ent:SetParent(self)

			table.insert(self.bullseyes, ent)
		end
	end

	function ENT:jcms_terminal_Callback()
		self:StartCountdown()
		return true, tostring( CurTime() + 60 )
	end

	function ENT:Think() 
		if not self:GetActive() or self:GetIsComplete() or self.jcms_beaconDead then return end 
		self:NextThink(CurTime() + 1)

		local chrg = self:GetCharge() + 1 / 60
		self:SetCharge(chrg) --60s to charge.

		if chrg >= 1 then 
			self:Complete()
		end

		if not jcms.director then return true end
		
		local selfPos = self:GetPos()
		for i, npc in ipairs(jcms.director.npcs) do 
			if not IsValid(npc) then continue end

			local npcTbl = npc:GetTable()
			if npcTbl.jcms_zombiebeacon_nextCheck and npcTbl.jcms_zombiebeacon_nextCheck > CurTime() then continue end
			npcTbl.jcms_zombiebeacon_nextCheck = CurTime() + math.Rand(3,6)

			local npcGetEnemy = npc.GetEnemy --Small optimisation.
			if npcGetEnemy and not npcGetEnemy(npc) then 
				local bullseye = self.bullseyes[math.random(#self.bullseyes)]
				if not IsValid(bullseye) then continue end 

				npc:SetEnemy(bullseye)
				npc:NavSetGoalPos(bullseye:GetPos())
			end
		end
		
		return true 
	end

	function ENT:OnTakeDamage(dmgInfo)
		if not self:GetActive() or self.jcms_beaconDead then --Don't take damage unless we're turned on.
			return
		end

		local attacker = dmgInfo:GetAttacker()
		if IsValid(attacker) and jcms.team_JCorp(attacker) then 
			dmgInfo:ScaleDamage(0.2) --Significantly reduced friendly-fire.
		else
			self:EmitSound("weapon.BulletImpact")
			self:EmitSound("SolidMetal.BulletImpact")
			--weapon.BulletImpact
			--SolidMetal.BulletImpact
			--MetalGrate.BulletImpact
		end

		dmgInfo:SetDamage( math.min(dmgInfo:GetDamage(), 100) ) --Don't take more than 100 in a single go.

		self:SetHealth( self:Health() - dmgInfo:GetDamage() )
		self:SetHealthFraction( self:Health() / self:GetMaxHealth() )

		if dmgInfo:GetDamage() > 5 then
			local ed = EffectData()
			ed:SetEntity(self)
			ed:SetScale(50)
			ed:SetColor(math.random(1,3))
			ed:SetOrigin(dmgInfo:GetDamagePosition())
			util.Effect("BloodImpact", ed)
		end

		if self:Health() < 0 and not self.jcms_beaconDead then 
			self:Die()
		end
	end

	function ENT:Die()
		self.jcms_beaconDead = true

		if self.alarmSound then
			self.alarmSound:Stop()
		end

		--self:AddFlags(FL_NOTARGET)
		for i, bullseye in ipairs(self.bullseyes) do 
			if not IsValid(bullseye) then continue end 
			bullseye:AddFlags( FL_NOTARGET )
		end

		if jcms.HasEpisodes() then 
			self:EmitSound("Weapon_StriderBuster.StickToEntity")
		end

		local filter = RecipientFilter()
		filter:AddAllPlayers()
		self.deathAlert = CreateSound(self, "ambient/alarms/combine_bank_alarm_loop4.wav", filter)
		self.deathAlert:SetSoundLevel(130)
		self.deathAlert:PlayEx(1, 50)
		self.deathAlert:SetDSP(38)
		self.deathAlert:ChangePitch(255, 4)

		timer.Simple(5, function()
			if IsValid(self) then

				if self.deathAlert then
					self.deathAlert:Stop()
				end

				timer.Simple(0, function() 
					if not IsValid(self) then return end
					local world = game.GetWorld()
					util.BlastDamage(world, world, self:WorldSpaceCenter(), 1500, 100)
				end)

				local ed = EffectData()
				ed:SetOrigin(self:WorldSpaceCenter())
				ed:SetFlags(6)
				util.Effect("jcms_blast", ed)

				ed:SetScale(500)
				ed:SetMagnitude(1.1)
				ed:SetFlags(1)
				util.Effect("jcms_blast", ed)

				util.ScreenShake(self:WorldSpaceCenter(), 50, 50, 10, 6000, true)
				self:EmitSound("ambient/explosions/explode_6.wav", 140, 110, 1, CHAN_AUTO)
				self:EmitSound("ambient/explosions/explode_2.wav", 100, 140, 1, CHAN_AUTO)

				local radSphere = ents.Create("jcms_radsphere")
				radSphere:SetPos(self:WorldSpaceCenter())
				radSphere:Spawn()

				self:Remove()
			end
		end)
	end

	function ENT:Complete()
		self:EmitSound("items/suitchargeok1.wav", 75, 120)
		self:EmitSound("doors/doormove2.wav", 75, 130)

		self.alarmSound:Stop()
		self:SetIsComplete(true)

		--self:AddFlags(FL_NOTARGET)
		for i, bullseye in ipairs(self.bullseyes) do 
			if not IsValid(bullseye) then continue end 
			bullseye:Remove()
		end

		self:SetNWString("jcms_terminal_modeData", "2")
		self:SetActive(false)
	end

	function ENT:StartCountdown()
		self:EmitSound("ambient/alarms/klaxon1.wav")

		local filter = RecipientFilter()
		filter:AddAllPlayers()
		self.alarmSound = CreateSound(self, "npc/attack_helicopter/aheli_crash_alert2.wav", filter )
		self.alarmSound:SetSoundLevel(90)
		self.alarmSound:PlayEx(1, 90)

		self:SetMaxHealth(500)
		self:SetHealth(self:GetMaxHealth())

		--self:RemoveFlags(FL_NOTARGET)
		for i, bullseye in ipairs(self.bullseyes) do 
			if not IsValid(bullseye) then continue end 
			bullseye:RemoveFlags( FL_NOTARGET )
		end

		self:SetActive(true)
	end

	function ENT:OnRemove()
		if self.deathAlert then
			self.deathAlert:Stop()
		end

		for i, bullseye in ipairs(self.bullseyes) do 
			if IsValid(bullseye) then 
				bullseye:Remove()
			end
		end

		if self.alarmSound then
			self.alarmSound:Stop()
		end
	end
end

if CLIENT then 

	function ENT:Think()
		self.closeAnim = self.closeAnim or 0

		local frac = self:GetCharge()
		if frac >= 1 then
			if not self.closedAnim then
				self.closedAnim = true
				self.closeAnim = 0
			end

			self.closeAnim = math.min(1, self.closeAnim + FrameTime())
			frac = 0.5 + math.ease.OutBounce(self.closeAnim) / 2

			if self.closeAnim > 0.2 and not self.closedSound then
				self.closedSound = true
				self:EmitSound("doors/door_metal_large_chamber_close1.wav", 120, 100)
			end
		else
			self.closedAnim = false
			self.closeAnim = (self.closeAnim*8 + frac*0.5)/9
			frac = self.closeAnim
		end

		self:ManipulateBonePosition(1, Vector(0, 0, 15*frac))
	end

	function ENT:DrawTranslucent(flags)
		if bit.band(flags, STUDIO_RENDER) then
			local pos, ang = self:GetPos(), self:GetAngles()
			pos:Add(ang:Up()*48.2)
			pos:Add(ang:Forward()*73.9)
			pos:Add(ang:Right()*17)
			ang:RotateAroundAxis(ang:Up(), 90)
			ang:RotateAroundAxis(ang:Forward(), 44)

			local w, h = 1082, 440
			local rendered = jcms.terminal_Render(self, pos, ang, w, h)
		end

		if self:GetIsComplete() then 
			local col = jcms.util_ColorFromInteger( jcms.util_colorIntegerJCorp )
			
			render.SetBlend(0.25)
			render.SetColorModulation((col.r/200), (col.g/200), (col.b/200))
			render.MaterialOverride(jcms.render_matShield)
			cam.Start3D()
				self:DrawModel()
			cam.End3D()
			render.MaterialOverride()
			render.SetColorModulation(1, 1, 1)
			render.SetBlend(1)
		end
	end
end