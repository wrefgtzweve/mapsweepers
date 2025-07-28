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
ENT.Base = "base_ai"
ENT.PrintName = "DOG"
ENT.Author = "Octantis Addons"
ENT.Category = "Map Sweepers"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_OPAQUE

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "GrabbedObject")
	self:NetworkVar("Bool", 0, "ShouldRagdoll")
end

if SERVER then
	function ENT:Initialize()
		self:SetModel("models/dog.mdl")
		
		self:SetHullType(HULL_LARGE)
		self:SetHullSizeNormal()
		self:SetSolid(SOLID_BBOX)

		self:SetMaxHealth(240)
		self:SetHealth(240)

		self:SetMaxLookDistance(3000)
		self:SetMoveInterval(0.01)
		self:SetArrivalSpeed(500)
		self:SetArrivalDistance(128)
		self:SetMaxYawSpeed(45)

		self:CapabilitiesAdd(bit.bor(CAP_MOVE_GROUND, CAP_MOVE_JUMP, CAP_TURN_HEAD, CAP_OPEN_DOORS))
		self:SetMoveType(MOVETYPE_STEP)
		self:SetNavType(NAV_GROUND)
		self:SetNPCClass(CLASS_PLAYER_ALLY)
		self:SetBloodColor(BLOOD_COLOR_MECH)
		
		self.nextAtkTime = 0
		self.blockedUntil = 0
		
		self.jcms_slowTurretReact = true
	end

	function ENT:OnTakeDamage(dmg)
		if self.jcms_dogDead then return end 

		if bit.band( dmg:GetDamageType(), bit.bor(DMG_BULLET, DMG_BUCKSHOT) ) > 0 then
			self:EmitSound("Computer.BulletImpact", 100, 100, 1)

			local ed = EffectData()
			ed:SetOrigin(dmg:GetDamagePosition())
			ed:SetMagnitude(1)
			ed:SetScale(1)
			ed:SetRadius(4)
			ed:SetNormal(VectorRand())
			util.Effect("Sparks", ed)
			dmg:ScaleDamage(0.35)
		end
		
		local grabbed = self:GetGrabbedObject()
		if dmg:GetInflictor() == grabbed or dmg:GetAttacker() == grabbed then
			dmg:ScaleDamage(0.05)
		end
		
		if dmg:GetDamage() > 0.1 then
			self:SetHealth( self:Health() - dmg:GetDamage() )
			
			if IsValid(dmg:GetAttacker()) then
				self:UpdateEnemyMemory(dmg:GetAttacker(), dmg:GetReportedPosition())
			end
			
			if self:Health() <= 0 then
				self.jcms_dogDead = true
				self:SetShouldRagdoll(true)
				hook.Call("OnNPCKilled", GAMEMODE, self, dmg:GetAttacker(), dmg:GetInflictor())
				
				timer.Simple(0.25, function()
					if IsValid(self) then
						self:Remove()
					end
				end)
			end
		end
		
		return 0
	end

	-- pose params:
	--[[
		0	gesture_height
		1	gesture_width
		2	move_yaw
		3	aim_yaw
		4	aim_pitch
		5	body_yaw
		6	spine_yaw
		7	neck_trans
		8	head_yaw
		9	head_pitch
		10	head_roll
	--]]
	
	function ENT:Think()
		local grabbedEnt = self:GetGrabbedObject()
		if IsValid(grabbedEnt) then
			local phys = grabbedEnt:GetPhysicsObject()
			if IsValid(phys) then
				local v, a = self:GetPos(), self:GetAngles()
				local intendedPos = v + a:Forward() * 200 + a:Up() * 100
				
				phys:Wake()
				phys:SetVelocity(intendedPos - phys:GetPos())
			else
				self:SetGrabbedObject(NULL)
			end
		end
	end
	
	-- Handy sequence IDs
	-- 49 : Throw APC
	-- 21 : Roll
	-- 8 : Chest pound
	-- 19 : Pound
	-- 40 : Throw

	function ENT:SelectSchedule()
		local time = CurTime()
		if self.blockedUntil > time then return end
		if self.jcms_dogDead then return end
		
		local grabbedObject = self:GetGrabbedObject()
		if IsValid(grabbedObject) then
			local bestAlyx
			
			if not grabbedObject:GetHackedByRebels() then
				-- Find an Alyx to hack this turret
				local alyxes = ents.FindByClass("npc_alyx")
				
				if #alyxes > 0 then
					local npcpos = self:WorldSpaceCenter()
					local bestDist = math.huge
					
					for i, alyx in ipairs(alyxes) do
						if alyx:Health() > 0 then
							local dist = alyx:WorldSpaceCenter():Distance(npcpos)
							if dist < bestDist then
								bestAlyx = alyx
								bestDist = dist
							end
						end
					end
				end
			end
			
			if IsValid(bestAlyx) then
				self:SetSaveValue("m_vecLastPosition", bestAlyx:GetPos())
				self:SetSchedule(SCHED_FORCED_GO_RUN)
			else
				local enemy = self:GetEnemy()
				if IsValid(enemy) then
					local enemypos = self:GetEnemyLastKnownPos(enemy)
					local viscon = enemy:Visible(enemy) and (CurTime()-self:GetEnemyLastTimeSeen(enemy))<1
					local dist = self:GetPos():Distance(enemypos)
					
					if viscon and dist < 1500 then
						self:DogThrow(enemy:WorldSpaceCenter() + enemy:GetVelocity())
					else
						self:SetSchedule(SCHED_ESTABLISH_LINE_OF_FIRE)
					end
				else
					
				end
			end
		else
			local enemy = self:GetEnemy()
			local canAtk = time > self.nextAtkTime
			if IsValid(enemy) then
				local enemypos = self:GetEnemyLastKnownPos(enemy)
				local viscon = enemy:Visible(enemy) and (CurTime()-self:GetEnemyLastTimeSeen(enemy))<1
				local dist = self:GetPos():Distance(enemypos)
				
				if viscon then
					if self:IsGoodGrabTarget(enemy) then
						-- Snatch that thing
						if dist < 300 then
							self:DogGrab(enemy)
						else
							self:SetSchedule(SCHED_CHASE_ENEMY)
						end
					else
						-- Kill this mf
						if enemy:IsPlayer() and CurTime() - self:GetEnemyFirstTimeSeen() < 1 then
							self.blockedUntil = time + 1
							self:EmitSound("NPC_dog.Growl_2")
							self:AddLayeredSequence(8, 99)
							self:SetSchedule(SCHED_COMBAT_FACE)
						else
							if dist < 250 then
								if canAtk then
									self:DogPound()
								end
							elseif dist < 1000 and canAtk then
								self:SetSchedule(SCHED_COMBAT_FACE)
								self:DogRoll(enemypos)
							else
								self:SetSchedule(SCHED_CHASE_ENEMY)
							end
						end
					end
				else
					self:SetSchedule(SCHED_CHASE_ENEMY)
				end
			else
				self:SetSchedule(SCHED_COMBAT_PATROL)
			end
		end
	end
	
	function ENT:DogPound()
		local time = CurTime()
		self.nextAtkTime = time + 2.5
		self.blockedUntil = time + 1.4
		
		self:EmitSound("NPC_dog.Angry_"..math.random(1,3))
		
		self:AddGestureSequence(19)
		timer.Simple(0.65, function()
			if IsValid(self) then
				self:EmitSound("physics/concrete/boulder_impact_hard4.wav", 100, 100)
				local ed = EffectData()
				ed:SetOrigin(self:GetPos())
				ed:SetScale(500)
				ed:SetEntity(self)
				util.Effect("ThumperDust", ed)
				self:DealPoundDamage(self:GetPos(), 1.1)
			end
		end)
		
		timer.Simple(0.72, function()
			if IsValid(self) then
				self:EmitSound("physics/concrete/boulder_impact_hard3.wav", 100, 90)
				local ed = EffectData()
				local pos = self:GetPos() + self:GetAngles():Forward() * 200
				ed:SetOrigin(pos)
				ed:SetScale(500)
				ed:SetEntity(self)
				util.Effect("ThumperDust", ed)
				self:DealPoundDamage(pos, 0.7)
			end
		end)
	end
	
	function ENT:DealPoundDamage(pos, mul)
		mul = mul or 1
		local dmgAmount = 30
		
		local force = Vector(0, 0, 400 * mul)
		force:Add( self:GetAngles():Forward() * 90 )
		local dmg = DamageInfo()
		dmg:SetAttacker(self)
		dmg:SetInflictor(self)
		dmg:SetDamageForce(force)
		dmg:SetReportedPosition(self:GetPos())
		dmg:SetDamageType(DMG_CLUB)
		
		local output = {}
		local trdata = { mask = MASK_SOLID, output = output }
		local downwards = Vector(0, 0, -20)
		
		util.ScreenShake(pos, 30, 50, 1*mul, 250, true)
		
		for i, ent in ipairs( ents.FindInSphere(pos, 250) ) do
			if self:Disposition(ent) ~= D_LI and self ~= ent then
				trdata.start = ent:GetPos()
				trdata.endpos = trdata.start + downwards
				trdata.filter = ent
				util.TraceEntityHull(trdata, ent)
				
				if output.Fraction < 1 then
					local power = (1 - output.Fraction)^2
					dmg:SetDamage(dmgAmount * mul * power)
					dmg:SetDamagePosition(ent:GetPos())
					ent:TakeDamageInfo(dmg)
					
					local phys = ent:GetPhysicsObject()
					if IsValid(phys) then
						local mt = ent:GetMoveType()
						if mt == MOVETYPE_STEP then
							ent:SetVelocity(force*power)
						elseif mt == MOVETYPE_WALK then
							ent:SetVelocity((force - ent:GetVelocity()*0.8)*power )
							
							if mul >= 1 then
								ent:EmitSound("Player.FallDamage")
							end
						elseif mt == MOVETYPE_VPHYSICS then
							phys:Wake()
							phys:AddVelocity(force*power)
							phys:AddAngleVelocity(VectorRand(-100*power, 100*power))
						end
					end
				end
			end
		end
	end
	
	function ENT:DogRoll(pos)
		local time = CurTime()
		self.nextAtkTime = time + 2
		self.blockedUntil = time + 1.2
		
		self:SetMoveType(MOVETYPE_FLYGRAVITY)
		self:AddGestureSequence(21)
		timer.Simple(0.2, function()
			if IsValid(self) then
				self:SetVelocity( (pos - self:GetPos()):GetNormalized()*900 )
			end
		end)
		
		timer.Simple(1, function()
			if IsValid(self) then
				self:SetMoveType(MOVETYPE_STEP)
			end
		end)
	end
	
	function ENT:DogGrab(ent)
		local phys = ent:GetPhysicsObject()
		
		if IsValid(phys) then
			self:SetGrabbedObject(ent)
			self:EmitSound("Weapon_PhysCannon.Pickup")
		end
	end
	
	function ENT:IsGoodGrabTarget(ent)
		return ent.GetHackedByRebels and ent:GetMoveType() == MOVETYPE_VPHYSICS
	end
	
	function ENT:DogThrow(at)
		local grabbedEnt = self:GetGrabbedObject()
		
		if IsValid(grabbedEnt) then
			self:EmitSound("NPC_dog.Laugh_1")
			
			local time = CurTime()
			self.nextAtkTime = time + 2
			self.blockedUntil = time + 2
			
			self:AddGestureSequence(40)
			timer.Simple(0.4, function()
				if IsValid(self) and IsValid(grabbedEnt) then
					self:SetGrabbedObject(NULL)
					
					local phys = grabbedEnt:GetPhysicsObject()
					if IsValid(phys) then
						local diff = at - grabbedEnt:GetPos()
						diff:Normalize()
						diff:Mul(800)
						diff.z = diff.z + 200
						phys:SetVelocity( diff )
						self:EmitSound("Weapon_PhysCannon.Launch")
					end
				end
			end)
		end
	end
end

if CLIENT then
	function ENT:Think()
		if self:GetShouldRagdoll() and not self.ragdollized then
			self:BecomeRagdollOnClient()
			self.ragdollized = true

			local ed = EffectData()
			ed:SetMagnitude(1.5)
			ed:SetOrigin(self:WorldSpaceCenter())
			ed:SetRadius(150)
			ed:SetNormal(self:GetAngles():Up())
			ed:SetFlags(5)
			ed:SetColor( jcms.util_ColorIntegerFast(230, 185, 255) )
			util.Effect("jcms_blast", ed)
		end
	end

	function ENT:Draw()
		if not self.ragdollized then
			self:DrawModel()
		end
	end
end
