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

EFFECT.MatBeam = Material "sprites/physbeama"
EFFECT.MatGlow = Material "particle/Particle_Glow_04"
EFFECT.MatLight = Material "particle/fire"
EFFECT.MatColor = Material "models/wireframe"
EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

function EFFECT:Init( data )
	self.color = jcms.util_ColorFromInteger(data:GetColor())
	self.alphaout = 1

	if data:GetFlags() == 1 then -- originates from a portal
		self.isPortal = true
		self.origin = data:GetOrigin()
		self.entpos = data:GetStart()
		self.scale = data:GetScale()
		self:GenPoints()
		self.t = -data:GetMagnitude() or 0 -- preparation/pre-spawn glow to warn the player
		self.tout = 1
		self.fadein = 0
		self.fadeinSpeed = math.random(5, 23)
		
		self:EmitSound("ambient/fire/ignite.wav", 75, 200)
	elseif data:GetFlags() == 0 or data:GetFlags() == 2 or data:GetFlags() == 3 then -- 0: appear, 2: disappear 3: disappear (ragdoll)
		self.isPortal = false
		self.ent = data:GetEntity()
		self.entpos = IsValid(self.ent) and self.ent:WorldSpaceCenter()
		self.t = 0
		
		self.tout = 3
		self.fadein = 1
		self.fadeinSpeed = 2
		self.reverse = data:GetFlags() == 2 or data:GetFlags() == 3
		self.useCollisionBounds = data:GetFlags() == 3

		if not self.entRenderOverride then
			self.entRenderOverride = self.ent.RenderOverride
			self.ent.RenderOverride = self.RenderEntity
			self.ent.jcms_spawneffect = self
		end
		
		self:EmitSound("ambient/fire/mtov_flame2.wav", 75, 160)
	end
end

function EFFECT:GenPoints()
	local selfTbl = self:GetTable()
	if not selfTbl.origin then return end

	if not selfTbl.points then
		selfTbl.points = {}
	else
		table.Empty(selfTbl.points)
	end

	selfTbl.points[1] = selfTbl.origin

	local n = math.random(4, 7)
	for i=1, n do
		local nv = LerpVector(math.Remap(i+math.random()-0.5,0,n+2,0,1), selfTbl.origin, selfTbl.entpos)
		nv.x = nv.x + math.Rand(-10, 10)
		nv.y = nv.y + math.Rand(-10, 10)

		local f = math.Remap(i, 0, n+1, 0, 1)
		local parabolic = math.max(0,-4*(f*f)+4*f)
		nv.z = nv.z + math.Rand(-10, 10) + parabolic * selfTbl.entpos:Distance(selfTbl.origin)/2
		selfTbl.points[i+1] = nv
	end
	selfTbl.points[n+2] = selfTbl.entpos
end

function EFFECT:Think()
	local selfTbl = self:GetTable()
	if selfTbl.t < selfTbl.tout then
		if selfTbl.isPortal then
			self:GenPoints()
			self:SetRenderBoundsWS(selfTbl.origin, selfTbl.entpos, Vector(16, 16, 16))
		elseif not selfTbl.entRenderOverride then
			selfTbl.entRenderOverride = selfTbl.ent.RenderOverride
			selfTbl.ent.RenderOverride = selfTbl.RenderEntity
			selfTbl.ent.jcms_spawneffect = self
		end

		selfTbl.fadein = selfTbl.t > 0 and (selfTbl.fadein*16 + 2)/15 or (selfTbl.fadein*self.fadeinSpeed + 1)/(self.fadeinSpeed+1)
		if selfTbl.t > 0 then
			selfTbl.alphaout = selfTbl.alphaout / 1.5
		end

		selfTbl.t = math.min(selfTbl.tout, selfTbl.t + FrameTime())
		return true
	else
		if not selfTbl.isPortal and IsValid(selfTbl.ent) then
			selfTbl.ent.RenderOverride = selfTbl.entRenderOverride
		end
		return false
	end
end

function EFFECT:Render()
	local selfTbl = self:GetTable()
	if selfTbl.isPortal and selfTbl.t <= 1 then
		local dist = EyePos():DistToSqr(self:WorldSpaceCenter())

		if selfTbl.points then
			local f = selfTbl.fadein * selfTbl.scale
			local color_white_alpha = ColorAlpha(color_white, selfTbl.alphaout*255)
			render.SetMaterial(selfTbl.MatBeam)
	
			local n = #selfTbl.points
			render.StartBeam(n)
			for i, point in ipairs(selfTbl.points) do
				render.AddBeam(point, math.Remap(i, 1, n, 7, 8*selfTbl.scale), math.Remap(i, 1, n, 0, 1), ColorAlpha(selfTbl.color, selfTbl.alphaout*255/n*i))
			end
			render.EndBeam()

			local center = selfTbl.entpos
			render.SetMaterial(selfTbl.MatGlow)
			local color_alpha = ColorAlpha(selfTbl.color, selfTbl.alphaout*255)

			render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )
				if dist < 1000^2 then
					render.DrawSprite(center, f*(128 + math.random()*16), f*(48 + math.random()*4), color_alpha)
					render.DrawSprite(center, f*(64 + math.random()*6), f*(72 + math.random()*18), color_alpha)
					render.DrawSprite(center, f*(32 + math.random()*8), f*(32 + math.random()*8), color_white_alpha)
				end

				if selfTbl.alphaout > 0.5 and dist < 2000^2 then
					render.SetMaterial(selfTbl.MatLight)
					render.DrawSprite(center, 72 + math.random()*32, 72 + math.random()*32, color_white_alpha)
				end
			render.OverrideBlend(false)
			render.SetBlend(1)
		end
	end
end

function EFFECT:RenderEntity()
	if not IsValid(self) then
		return
	end

	local effect = self.jcms_spawneffect
	if not IsValid(effect) then 
		self.RenderOverride = nil 
		self.jcms_spawneffect = nil 
		self:DrawModel()
		return 
	end


	local up = Vector(0,0,1)
	local dn = Vector(0,0,-1)

	local mins, maxs
	if effect.useCollisionBounds then --needed to work with ragdolls
		mins, maxs = self:GetCollisionBounds()
		mins:Sub(jcms.vectorOne)
		maxs:Add(jcms.vectorOne)
	else
		mins, maxs = self:GetModelRenderBounds()
	end
	local mypos = self:GetPos()
	mins:Add(mypos)
	maxs:Add(mypos)

	local eyeDist = EyePos():DistToSqr(mypos)

	local time = effect.reverse and math.max(0, 2-effect.t) or effect.t

	local vbound = LerpVector(time-1 < 1 and math.ease.InOutCubic(math.Clamp(time-1, 0, 1)) or time-1, mins, maxs)
	local vbound2 = LerpVector(time < 1 and math.ease.InOutCubic(math.Clamp(math.sqrt(time), 0, 1)) or time, mins, maxs)
	local old = render.EnableClipping(true)

	if eyeDist < 4000^2 then
		if time < 2 and eyeDist < 1500^2 then
			local centered = Vector(mypos)
			centered.z = (time>1 and vbound or vbound2).z

			local f = time%1
			local parabolic = math.max(0,-4*(f*f)+4*f)
			render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )
				render.SetMaterial(effect.MatGlow)
				render.DrawQuadEasy(centered, up, math.Rand(48,72)*parabolic, math.Rand(48,72)*parabolic, effect.color)
				render.SetMaterial(effect.MatLight)
				render.DrawSprite(centered, 96*parabolic, 12*parabolic, effect.color)
			render.OverrideBlend(false)
		end

		-- Model
		render.PushCustomClipPlane(dn, dn:Dot(vbound2))
			render.PushCustomClipPlane(up, up:Dot(vbound))
				render.MaterialOverride(effect.MatColor)
					local mr,mg,mb = render.GetColorModulation()
					local mod = Lerp(time-1,128,48)

					local cr, cg, cb = effect.color:Unpack()
					render.SetColorModulation(cr/mod, cg/mod, cb/mod)
					self:DrawModel()
					render.SetColorModulation(mr,mg,mb)
				render.MaterialOverride()
			render.PopCustomClipPlane()
		render.PopCustomClipPlane()
	end

	-- Overlay
	render.PushCustomClipPlane(dn, dn:Dot(vbound))
		self:DrawModel()
	render.PopCustomClipPlane()

	render.EnableClipping(old)
end
