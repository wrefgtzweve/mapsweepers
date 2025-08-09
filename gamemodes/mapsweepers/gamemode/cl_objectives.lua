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

-- // Current {{{

	jcms.objective_title = jcms.objective_title or nil
	jcms.objectives = jcms.objectives or {}

-- // }}}

-- // Functions {{{

	function jcms.objective_Localize(obj)
		if type(obj) == "string" then
			local key1 = "jcms.obj_" .. obj
			local loc = language.GetPhrase(key1)
			if loc == key1 then
				loc = language.GetPhrase(obj)
			end
			return loc
		else
			return "???"
		end
	end

	function jcms.objective_UpdateEverything(missionType, newObjectives)
		jcms.objective_title = tostring(missionType)
		table.Empty(jcms.objectives)
		table.Add(jcms.objectives, newObjectives)
	end

-- // }}}

-- // Drawing {{{

	function jcms.objective_Draw(i, objective)
		local off = 2

		local color, colorDark = jcms.color_bright, jcms.color_dark
		if objective.completed then
			color, colorDark = jcms.color_bright_alt, jcms.color_dark_alt
		end

		local str = jcms.objective_Localize(objective.type)
		local x = objective.progress
		local n = objective.n

		if x and n>0 then
			local progress = math.Clamp(x / n, 0, 1)
			objective.fProgress = progress
			objective.anim_fProgress = ((objective.anim_fProgress or progress)*8 + progress)/9

			local barw = 200
			local progressString
			if objective.percent then
				progressString = string.format("%d%%  ", progress*100)
			else
				progressString = string.format("%d/%d  ", x, n)
			end
			surface.SetFont("jcms_hud_small")
			local tw = surface.GetTextSize(progressString)

			local f = objective.anim_fProgress
			draw.SimpleText(progressString, "jcms_hud_small", 24, 16, colorDark, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(str, "jcms_hud_small", 32, 2, colorDark, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
			surface.SetDrawColor(colorDark)
			surface.DrawRect(24 + tw, 16, barw - tw, 6)
			render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )
				surface.SetDrawColor(color)
				surface.DrawRect(24 + off + tw, 16 + off, (barw - tw)*f, 4)
				draw.SimpleText(progressString, "jcms_hud_small", 24 + off, 16 + off, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				draw.SimpleText(str, "jcms_hud_small", 32 + off, 2 + off, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
			render.OverrideBlend( false )   
		else
			if objective.style == 1 then -- TODO more styles + put all of that code into tables. This is quick and rough cuz I gtg
				color = jcms.color_alert
				draw.SimpleText(str, "jcms_hud_small", 0, -2, colorDark, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				
				local timestr = string.FormattedTime(x, "%02i:%02i")
				draw.SimpleText(timestr, "jcms_hud_medium", 16, -2+48, colorDark, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

				render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )
					draw.SimpleText(str, "jcms_hud_small", off, -2+off, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					draw.SimpleText(timestr, "jcms_hud_medium", 16+off, -2+48+off, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				render.OverrideBlend( false ) 

				return false, 84
			else
				draw.SimpleText(str, "jcms_hud_small", 32, -2, colorDark, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )
					draw.SimpleText(str, "jcms_hud_small", 32 + off, -2 + off, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				render.OverrideBlend( false ) 
			end 
		end

		return true, 84
	end

-- // }}}
