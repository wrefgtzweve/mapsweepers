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

EFFECT.mat_glow = Material "sprites/blueglow2"
EFFECT.mat_ring = Material "effects/select_ring"
EFFECT.mat_spark = Material "effects/spark"
EFFECT.mat_shield = Material "models/shiny"
EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

local function drawShieldModel(self, ent, sc, color)
	for i=1, ent:GetBoneCount() do
		ent:ManipulateBoneScale(i, Vector(sc, sc, sc))
	end

	ent:RemoveAllDecals()
	
	local oldMat = ent:GetMaterial()
	render.SetColorModulation(color.r/32, color.g/32, color.b/32)
	render.ModelMaterialOverride(self.mat_shield)
	render.MaterialOverride(self.mat_shield)
	render.OverrideBlend(true, BLEND_SRC_COLOR, BLEND_ONE, BLENDFUNC_ADD)
		ent:SetupBones()
		ent:DrawModel()
	render.OverrideBlend(false)
	render.MaterialOverride()
	render.ModelMaterialOverride()
	render.SetColorModulation(1, 1, 1)
	
	for i=1, ent:GetBoneCount() do
		ent:ManipulateBoneScale(i, jcms.vectorOne)
	end
end

function EFFECT:Init( data )
	self.t = 0
	if data:GetFlags() == 0 then -- Player damaged with shields on
		self.mode = 0
		self.pos = data:GetOrigin()
		self.normal = data:GetNormal()
		self.scale = data:GetScale()
		self.tout = math.Rand(0.15, 0.25)
	elseif data:GetFlags() == 1 then -- Shield has been broken
		self.mode = 1
		self.ent = data:GetEntity()
		self.tout = math.Rand(0.22, 0.28)
		
		self.sparks = {}
		for i=1, math.random(20, 40) do
			local spark = {}
			spark.start = VectorRand(-16, 16)
			spark.endpos = spark.start + spark.start:GetNormalized()*math.Rand(16, 64)
			spark.width = math.Rand(1, 4)^2
			spark.off = math.random()*0.3
			table.insert(self.sparks, spark)
		end
	elseif data:GetFlags() == 2 then -- Shield has been fully restored
		self.mode = 2
		self.ent = data:GetEntity()
		self.t = -0.2
		self.tout = 1

		if self.ent == LocalPlayer() then
			jcms.hud_shieldRestoredAnim = 0
		end
	end

	self.color1 = jcms.util_ColorFromInteger( data:GetColor() )
	self.color2 = Color( self.color1:Unpack() )
	self.color3 = Color( self.color1:Unpack() )
end

function EFFECT:Think()
	if (self.t < self.tout) and (self.mode) and (not self.ent or IsValid(self.ent)) then
		if self.ent then
			local pos = self.ent:GetPos()
			self:SetRenderBoundsWS(pos - self.ent:OBBMins(), pos + self.ent:OBBMaxs(), Vector(4, 4, 4))
		end
		self.t = math.min(self.tout, self.t + FrameTime())
		return true
	else
		return false
	end
end

function EFFECT:Render()
	if self.mode == 0 then
		local f = self.t/self.tout
		
		local col1 = self.color1
		local col2 = self.color2
		col2:SetUnpacked( col1:Unpack() )
		col2.a = 64
		local col3 = self.color3
		col3.r = col1.r * f
		col3.g = col1.g * f
		col3.b = col1.b * f

		render.SetMaterial(self.mat_glow)
		local size = Lerp(f, 32, 0)*self.scale
		render.DrawQuadEasy(self.pos, self.normal, size/2, size/2, col1, math.random()*360)

		render.DrawSprite(self.pos, size*2, size, col2)
		render.SetMaterial(self.mat_ring)
		size = Lerp(math.ease.InQuart(f), 0, 16)*self.scale
		render.DrawQuadEasy(self.pos, self.normal, size, size, col3, math.random()*360)
	elseif self.mode == 1 then
		if IsValid(self.ent) then
			local boneId = self.ent:LookupBone("ValveBiped.Bip01_Spine1")
			local matrix = boneId and self.ent:GetBoneMatrix(boneId)
			local mypos = matrix and matrix:GetTranslation() or self.ent:WorldSpaceCenter()
			local color = self.color1
			
			render.SetMaterial(self.mat_spark)
			local sparkStart = Vector(mypos)
			local sparkEnd = Vector(mypos)
			for i, spark in ipairs(self.sparks) do
				local f = math.Clamp((self.t-spark.off)/(self.tout-spark.off*2), 0, 1)
				local anim = Lerp(f, -0.5, 0.7)
				local parabolic = 1-f^2
				sparkStart:Add(spark.start)
				sparkEnd:Add(spark.endpos)

				render.DrawBeam(sparkStart, sparkEnd, spark.width*parabolic, anim+0.5, anim^2, color)
				
				sparkEnd:Sub(spark.endpos)
				sparkStart:Sub(spark.start)
			end
			
			local parabolic = self.t*2/self.tout
			if parabolic < 1 then
				local sc = Lerp(parabolic, 1, 3)
				drawShieldModel(self, self.ent, sc, color)
			end
		end
	elseif self.mode == 2 then
		if self.t < 0 or not IsValid(self.ent) then
			return
		end
		
		local rings = 6
		local vUp = jcms.vectorUp
		local radius = self.ent:BoundingRadius()
		local color = self.color1
		
		local boneId = self.ent:LookupBone("ValveBiped.Bip01_Head1")
		local matrix = boneId and self.ent:GetBoneMatrix(boneId)
		local ringpos = matrix and matrix:GetTranslation() or self.ent:WorldSpaceCenter()
		ringpos.z = self.ent:GetPos().z
		
		local baseRingZ = ringpos.z
		for i=1, rings do
			local f = math.ease.InOutQuart(math.Clamp((self.t - (i*2/rings)/rings) / (self.tout - 2/rings), 0, 1))
			local parabolic = math.max(0,-4*(f*f)+4*f)
			local size = Lerp(parabolic^0.5, 24, 48)
			render.SetMaterial(self.mat_ring)
			ringpos.z = baseRingZ + Lerp(f, radius*0.1, radius*1.6)
			render.DrawQuadEasy(ringpos, vUp, size, size, color, 0)
		end
		
		local f = math.ease.InOutQuart(self.t/self.tout, 0, 1)
		local parabolic = math.max(0,-4*(f*f)+4*f)^0.3
		local sc = Lerp(parabolic, 1, 1.5)
		drawShieldModel(self, self.ent, sc, color)
	end
end
