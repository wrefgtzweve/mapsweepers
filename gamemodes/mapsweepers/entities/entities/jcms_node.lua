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

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Node"
ENT.Author = "Octantis Addons"
ENT.Category = "Map Sweepers"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/xqm/button2.mdl")
		self.distance = 0
	end

	if CLIENT then
		self.colourCore = Color(255, 255, 255)
		self.colourBeam = Color(255, 255, 255)

		local nextNode = self:GetNextNode()
		if IsValid(nextNode) then
			local r = self:BoundingRadius()
			self:SetRenderBoundsWS(self:WorldSpaceCenter(), nextNode:WorldSpaceCenter(), Vector(r,r,r))
		end

		self.trackPosition = self:GetTrackPosition() --Optimisation
	end
end

function ENT:SetupDataTables()
	self:NetworkVar("Entity", "NextNode")
	self:NetworkVar("Bool", 0, "IsEnabled")
	self:NetworkVar("Float", 0, "Altitude")
	self:NetworkVar("Vector", 0, "EnergyColour")

	if SERVER then 
		self:SetAltitude(24)
		self:SetIsEnabled(true)
		self:SetEnergyColour( Vector(1, 0.1, 0.1) )
	end
end

function ENT:GetTrackPosition()
	local v = self:GetPos()
	local aUp = self:GetAngles():Up()
	aUp:Mul(self:GetAltitude())
	v:Add(aUp)
	return v
end

if SERVER then	
	function ENT:ConnectNode(nextNode)
		assert(IsValid(nextNode) and nextNode:GetClass() == "jcms_node", "nextNode must be a valid jcms_node entity")
		self:SetNextNode(nextNode)
		self.distance = self:GetTrackPosition():Distance( nextNode:GetTrackPosition() )

		local angTo = (nextNode:GetPos() - self:GetPos()):Angle()
		angTo.p = 0

		self:SetAngles(angTo)
	end
end

if CLIENT then
	ENT.MatBeam = Material("effects/bloodstream")
	ENT.MatDirBeam = Material("effects/spark")
	ENT.MatGlow = Material("sprites/gmdm_pickups/light")

	local emt = FindMetaTable("Entity")

	function ENT:Draw()
		local eyeDist = jcms.EyePos_lowAccuracy:DistToSqr(emt.GetTable(self).trackPosition)
		if eyeDist < 1500^2 then 
			emt.DrawModel(self)
			--self:DrawModel()
		end
	end

	function ENT:DrawTranslucent()
		if render.GetRenderTarget() then return end

		local selfTbl = emt.GetTable(self) --self:GetTable()

		local intendedColour = selfTbl:GetEnergyColour()
		local isEnabled = selfTbl:GetIsEnabled()

		local trackPos = selfTbl.trackPosition
		render.SetMaterial(selfTbl.MatGlow)
		local distToEyes = jcms.EyePos_lowAccuracy:Distance(trackPos)

		local iR, iG, iB = intendedColour:Unpack()
		selfTbl.colourBeam:SetUnpacked(iR * 255, iG * 255, iB * 255)
		if distToEyes < 1100 then
			selfTbl.colourCore:SetUnpacked(iR * 128 + 127, iG * 128 + 127, iB * 128 + 127)
		end

		
		render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )
			if distToEyes < 600 then
				local ps = isEnabled and 0 or 8
				render.DrawSprite(trackPos, 32 + ps + math.random()*4, 24 + ps + math.random()*4, selfTbl.colourBeam)
				
				if distToEyes < 400 then
					render.DrawSprite(trackPos, 20 + ps + math.random()*4, 20 + ps + math.random()*4, selfTbl.colourCore)
				end
			end

			local nextNode = selfTbl:GetNextNode()

			if IsValid(nextNode) then
				local scale = math.max(1, distToEyes / 1000)
				local nextNodeTrackPos = nextNode.trackPosition

				if isEnabled then
					local cTime = CurTime()

					local len = trackPos:Distance( nextNodeTrackPos )/200
					local u = ( -cTime )%1
					render.SetMaterial(selfTbl.MatBeam)
					render.DrawBeam(trackPos, nextNodeTrackPos, 16*scale, u, u+len, selfTbl.colourBeam)
					
					if distToEyes < 1100 then 
						local u = ( cTime*2 )%1
						render.SetMaterial(selfTbl.MatDirBeam)
						render.DrawBeam(trackPos, nextNodeTrackPos, 32*(scale/2+0.5), u*5, u*5-4, selfTbl.colourCore)
					end
				else
					render.SetMaterial(selfTbl.MatDirBeam)
					render.DrawBeam(trackPos, nextNodeTrackPos, (1 + math.random()*2)*(scale/2+0.5), 1, -0.3, selfTbl.colourBeam)
				end
			end
		render.OverrideBlend( false )
	end
end
