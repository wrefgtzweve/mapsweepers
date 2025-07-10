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

EFFECT.mat = Material "effects/spark"
EFFECT.mat_light = Material "sprites/light_glow02_add"
EFFECT.mat_fire = Material "effects/fire_cloud1.vtf"
EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

function EFFECT:Init( data )
	self.start = data:GetStart()
	self.endpos = data:GetOrigin()
	self.isIncendiary = data:GetFlags() == 1

	self:SetRenderBoundsWS(self.start, self.endpos)

	self.t = 0
	self.tout = 0.25
	self.color = Color(255, 255, 255, 255)
end

function EFFECT:Think()
	if self.t < self.tout then
		self.t = math.min(self.tout, self.t + FrameTime())
		return true
	else
		return false
	end
end

function EFFECT:Render()
	local f = self.t / self.tout
	local ff = math.ease.InCirc(1 - f)
	
	self.color.r = 255
	self.color.g = 200*ff
	self.color.b = 200*ff
	self.color.a = 256*ff
	
	render.SetMaterial(self.mat)
	render.DrawBeam(self.start, self.endpos, (self.isIncendiary and 32 or 16)*ff, 0, 0.8, self.color)
	render.SetMaterial(self.mat_light)
	render.DrawSprite(self.endpos, 64 * ff, 48 * ff, self.color)
	
	if self.isIncendiary then
		self.color.r = 255
		self.color.g = 255
		self.color.b = 255
		self.color.a = 255
		render.SetMaterial(self.mat_fire)
		render.DrawBeam(self.start, self.endpos, Lerp(f, 16, 32), 0, ff, self.color)
		render.DrawSprite(self.endpos, 127 * ff, 120 * ff, self.color)
	end
end
