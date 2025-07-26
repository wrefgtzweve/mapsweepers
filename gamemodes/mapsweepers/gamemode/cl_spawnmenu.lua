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

local offMatrix = Matrix()
local offVector = Vector(0, 0, 0)

if IsValid(jcms.spawnmenu_mouseCapturePanel) then
	jcms.spawnmenu_mouseCapturePanel:Remove()
end

-- // Orders {{{

	jcms.orders = jcms.orders or {}
	jcms.spawnmenu_scrolled = false
	
	function jcms.orders_Hash()
		return jcms.util_Hash(jcms.orders)
	end
	
	jcms.orders_lists = {}
	
	function jcms.orders_RebuildLists()
		for i = 1, 8 do
			if not jcms.orders_lists[i] then
				jcms.orders_lists[i] = {}
			else
				table.Empty(jcms.orders_lists[i])
			end
		end
		
		for orderid, data in pairs(jcms.orders) do
			table.insert(jcms.orders_lists[(data.category or jcms.SPAWNCAT_UTILITY) + 1], orderid)
		end
		for _, catTbl in pairs(jcms.orders_lists) do --Consistent sorting/order.
			table.sort(catTbl, function(A, B) 
				return jcms.orders[A].slotPos < jcms.orders[B].slotPos
			end)
		end
	end
	
	jcms.orders_RebuildLists()

-- // }}}

-- // Order category materials {{{

	jcms.orders_categoryMats = {
		Material "jcms/orderwheel/turrets.png",
		Material "jcms/orderwheel/utility.png",
		Material "jcms/orderwheel/mines.png",
		Material "jcms/orderwheel/mobility.png",
		Material "jcms/orderwheel/orbitals.png",
		Material "jcms/orderwheel/supplies.png",
		Material "jcms/orderwheel/mission.png",
		Material "jcms/orderwheel/defensive.png"
	}

-- // }}}

-- // Aux {{{

	local function drawSegment(x, y, ang1, ang2, r1, r2, inset)
		ang1, ang2 = math.min(ang1, ang2), math.max(ang1, ang2)
		r1, r2 = math.min(r1, r2), math.max(r1, r2)
		inset = inset or 0

		local vtx = {
			{ x = x + math.cos(ang2)*r2, y = y + math.sin(ang2)*r2 },
			{ x = x + math.cos(ang2)*r1, y = y + math.sin(ang2)*r1 },
			{ x = x + math.cos(ang1)*r1, y = y + math.sin(ang1)*r1 },
			{ x = x + math.cos(ang1)*r2, y = y + math.sin(ang1)*r2 },
		}

		local cx, cy = x, y
		if inset > 0 then
			local n = #vtx
			cx, cy = 0, 0
			for i, v in ipairs(vtx) do
				cx = cx + v.x
				cy = cy + v.y
			end
			cx, cy = cx/n, cy/n

			for i, v in ipairs(vtx) do
				local dist = math.Distance(v.x, v.y, cx, cy)
				local ndist = math.max(dist - inset, 0)
				v.x = Lerp(ndist/dist, cx, v.x)
				v.y = Lerp(ndist/dist, cy, v.y)
			end
		end

		draw.NoTexture()
		surface.DrawPoly(vtx)
		return cx, cy
	end
	
	jcms.mousewheel = 0
	jcms.mousewheelOccupied = false 
	
	function jcms.mousewheel_Occupy()
		jcms.mousewheelOccupied = true
	end

-- // }}}

-- // Main {{{

	jcms.spawnmenu_isOpen = false
	jcms.spawnmenu_isContext = false
	jcms.spawnmenu_mouseCapturePanel = NULL
	jcms.spawnmenu_selectedOption = nil
	jcms.spawnmenu_selectedOrders = { 1, 1, 1, 1, 1, 1, 1, 1 }
	jcms.spawnmenu_lastUseTime = 0

	function jcms.spawnmenu_Update()
		if (not jcms.spawnmenu_isOpen) then 
			return 
		end

		local selectedOption
		local fromKeyboard = false
		
		if jcms.spawnmenu_isContext then
			jcms.mousewheel_Occupy()
			for i=2, 5 do
				if input.IsKeyDown(i) then
					selectedOption = i-1
					fromKeyboard = true
					break
				end
			end
		end

		local mx, my = ScrW()/2, ScrH()/2
		if IsValid(jcms.spawnmenu_mouseCapturePanel) then
			mx, my = jcms.spawnmenu_mouseCapturePanel:LocalCursorPos()
		end
		
		if not selectedOption and math.DistanceSqr(mx, my, ScrW()/2, ScrH()/2) > (jcms.spawnmenu_isContext and 8*8 or 64*64) then
			local a = math.atan2(my-ScrH()/2, mx-ScrW()/2)
			if jcms.spawnmenu_isContext then
				local sector = math.floor( (a+math.pi/4)/(math.pi/2)+1 )%4 + 1
				selectedOption = sector
			else
				local sector = math.floor( (a+math.pi/8)/(math.pi/4) )%8 + 1
				selectedOption = sector
				
				if jcms.spawnmenu_selectedOrders[sector] then
					if jcms.mousewheel ~= 0 then
						surface.PlaySound("weapons/zoom.wav")
						jcms.spawnmenu_scrolled = true
					end

					if jcms.mousewheel > 0 then
						jcms.spawnmenu_selectedOrders[sector] = math.min(jcms.spawnmenu_selectedOrders[sector] + 1, #jcms.orders_lists[sector])
					elseif jcms.mousewheel < 0 then
						jcms.spawnmenu_selectedOrders[sector] = math.max(jcms.spawnmenu_selectedOrders[sector] - 1, 1)
					end
				end
			end
		end

		jcms.spawnmenu_selectedOption = selectedOption
		if selectedOption and (fromKeyboard or input.IsMouseDown(MOUSE_LEFT)) then
			if jcms.spawnmenu_isContext then
				GAMEMODE:OnContextMenuClose()
			else
				if CurTime() - jcms.spawnmenu_lastUseTime > 0.25 then
					local selectionId = jcms.spawnmenu_selectedOrders[selectedOption]
					local ordersList = jcms.orders_lists[selectedOption]
					local selectedOrder = ordersList and jcms.orders_lists[selectedOption][ selectionId ]
					
					if selectedOrder then
						RunConsoleCommand("jcms_order", selectedOrder)
						GAMEMODE:OnSpawnMenuOpen()
					end
				end
			end
		end

	end

	local lasertracer = Material "effects/laser_tracer.vmt"
	function jcms.spawnmenu_PaintMouseCapture(p, w, h)
		local cx, cy = p:LocalCursorPos()
		local fx, fy = w/2, h/2
		local dist = math.Distance(cx, cy, fx, fy)
		
		local dir = math.atan2(cy-fy, cx-fx)
		local cos, sin = math.cos(dir), math.sin(dir)
		
		surface.SetMaterial(lasertracer)
		surface.SetDrawColor(jcms.color_bright)
		surface.DrawTexturedRectRotated(fx + cos*dist/2, fy + sin*dist/2, 16, dist, math.deg(-dir)+90)
		local size = Lerp(1-1/(dist/128+1), 8, 24)

		surface.SetDrawColor(jcms.color_bright)
		render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )
		jcms.draw_Circle(cx, cy, size, size, 2, 5)
		render.OverrideBlend( false )
		size = size - 4

		surface.SetDrawColor(jcms.color_alert)
		jcms.draw_Circle(cx, cy, size, size, 2, 5)
	end

	function jcms.spawnmenu_Draw()
		local blend = jcms.hud_spawnmenuAnim or 0
		if blend <= 0.03 then return end

		surface.SetAlphaMultiplier(blend^2)

		local sw, sh = ScrW()/2, ScrH()/2
		cam.Start2D()

		if jcms.spawnmenu_isContext then
			render.SetColorMaterial()
			draw.NoTexture()

			local commands = { "go", "attack", "look", "defend" }
			for i=1, 4 do
				local clr = jcms.color_bright
				local clr_dark = jcms.color_dark
				if i == jcms.spawnmenu_selectedOption then
					clr = jcms.color_bright_alt
					clr_dark = jcms.color_dark_alt
				end
				
				local a = math.pi/2 * (-2 + i)
				local size = 128
				local cos, sin = math.cos(a), math.sin(a)
				local dist = size / 1.4142135 + 4
				surface.SetDrawColor(clr.r, clr.g, clr.b, 100)
				surface.DrawTexturedRectRotated(sw + cos*dist, sh + sin*dist, size, size, 45)

				local dist2 = dist - size*0.4
				local dist3 = dist + size*0.2
				local commandStr = language.GetPhrase("jcms." .. commands[i])
				draw.SimpleText(commandStr, "jcms_medium", sw + cos*dist3, sh + sin*dist3, clr_dark, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleTextOutlined(commandStr, "jcms_medium", sw + cos*dist3, sh + sin*dist3 - 2, clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, clr_dark)
				draw.SimpleTextOutlined("["..i.."]", "jcms_medium", sw + cos*dist2, sh + sin*dist2, clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, jcms.color_dark)	
			end
		else
			local span = math.pi*2/8
			local ca = -span/2*blend
			local dist = 150
			
			local myCash = LocalPlayer():GetNWInt("jcms_cash", 0)
			
			local classData = jcms.class_GetLocPlyData()
			
			for i=1, 8 do
				local clr = jcms.color_bright
				local clr_dark = jcms.color_dark
				local off, inset = 2, 4
				local alphamul = 1
				local cos, sin = math.cos(ca + span/2), math.sin(ca + span/2)
				
				local selectionId = jcms.spawnmenu_selectedOrders[i]
				local selectedOrder = jcms.orders_lists[i][ selectionId ]
				if not selectedOrder then
					alphamul = 0.25
				end
				
				if selectedOrder then
					local alignX = cos > 0.2 and TEXT_ALIGN_LEFT or cos < -0.2 and TEXT_ALIGN_RIGHT or TEXT_ALIGN_CENTER

					local orderData = jcms.orders[ selectedOrder ]
					local orderName = language.GetPhrase("jcms." .. selectedOrder)

					local costMult, coolDownMult = jcms.class_GetCostMultipliers(classData, orderData)
					local timeUntilUse = (orderData.nextUse or 0) - CurTime()
					local affordable = math.ceil(orderData.cost*costMult) <= myCash

					if (timeUntilUse > 0) or (not affordable) then
						alphamul = 0.25
					end

					if affordable and timeUntilUse <= 0 and i == jcms.spawnmenu_selectedOption then
						clr = jcms.color_bright_alt
						clr_dark = jcms.color_dark_alt
						off = 0
						inset = 2
					end

					surface.SetDrawColor(clr.r, clr.g, clr.b, 60*alphamul)
					drawSegment(sw, sh, ca, ca+span, 128, 128 + 64, 4)
					surface.SetDrawColor(clr, clr, clr, 255*alphamul)
					drawSegment(sw, sh, ca, ca+span, 128 - 4 - off, 128 - off, inset)

					if (i == jcms.spawnmenu_selectedOption or timeUntilUse >= 0 or i-1 == jcms.SPAWNCAT_MISSION) then
						local tx, ty = sw + cos*dist, sh + sin*dist - 2 - 16
						-- Detailed view

						if not affordable then
							surface.SetAlphaMultiplier(0.5 * blend^2)
						end

						local tw, th = draw.SimpleTextOutlined(orderName, "jcms_medium", tx, ty, clr, alignX, TEXT_ALIGN_BOTTOM, 1, clr_dark)
						if timeUntilUse <= 0 then
							ty = ty + th - 8
							tw, th = draw.SimpleTextOutlined(jcms.util_CashFormat(math.ceil(orderData.cost*costMult)) .. " (J)", "jcms_missiondesc", tx, ty-4, clr, alignX, TEXT_ALIGN_CENTER, 1, clr_dark)

							ty = ty + th + 4
							draw.SimpleTextOutlined(language.GetPhrase("jcms.cooldown"):format(string.FormattedTime(math.ceil(orderData.cooldown*coolDownMult), "%02i:%02i")), "jcms_small", tx, ty, clr, alignX, TEXT_ALIGN_BOTTOM, 1, clr_dark)
						else
							ty = ty + th - 4
							draw.SimpleTextOutlined(language.GetPhrase("jcms.cooldown"):format(string.FormattedTime(timeUntilUse, "%02i:%02i")), "jcms_missiondesc", tx, ty, jcms.color_alert, alignX, TEXT_ALIGN_BOTTOM, 1, clr_dark)
						end

						if not affordable then
							surface.SetAlphaMultiplier(blend^2)
						end
					else
						local tx, ty = sw + cos*(dist + 16), sh + sin*(dist + 16) - 2

						surface.SetMaterial(jcms.orders_categoryMats[i])
						surface.SetDrawColor(clr)
						surface.DrawTexturedRectRotated(tx, ty, 64, 64, 0)
					end
				else
					surface.SetDrawColor(clr.r, clr.g, clr.b, 60*alphamul)
					drawSegment(sw, sh, ca, ca+span, 128, 128 + 64, 4)
				end
				
				ca = ca + span
			end
			
			if jcms.spawnmenu_selectedOption then
				local selectedOption = jcms.spawnmenu_selectedOption
				local selectionId = jcms.spawnmenu_selectedOrders[selectedOption]
				local orderList = jcms.orders_lists[selectedOption]
				
				local selectedOrder = orderList[selectionId]
				local orderData = jcms.orders[ orderList[selectionId] ]
				if orderData then
					local orderDesc = language.GetPhrase("jcms." .. selectedOrder .. "_desc")
					draw.SimpleTextOutlined(orderDesc, "jcms_small", ScrW()/2, ScrH()/2 - 228, jcms.color_bright, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.5, jcms.color_dark)
				end
				
				local maxDisplayed = 11
				local th = 20
				
				for i, order in ipairs(orderList) do
					local iOff = i - selectionId + 1
					if iOff < -maxDisplayed/2+1 or iOff > maxDisplayed/2+1 then
						continue
					end
					
					local orderData = jcms.orders[ order ]
					local orderName = language.GetPhrase("jcms." .. order)
					
					local costMult, coolDownMult = jcms.class_GetCostMultipliers(classData, orderData)
					local timeUntilUse = (orderData.nextUse or 0) - CurTime()
					local affordable = math.ceil(orderData.cost*costMult) <= myCash
					
					if (timeUntilUse > 0) or (not affordable) then
						alphamul = 0.25
					end
				
					local clr = jcms.color_bright
					local clr_dark = jcms.color_dark
					
					if i == selectionId then
						clr = jcms.color_bright_alt
						clr_dark = jcms.color_dark_alt
					end
				
					if (affordable and timeUntilUse <= 0) or (i == selectionId) then
						local tw, th = draw.SimpleTextOutlined(orderName, "jcms_small", ScrW()/2, ScrH()/2 - (iOff-1)*th, clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, clr_dark)
						
						if i == selectionId then
							local pulse = Lerp(math.abs(math.cos(CurTime()*4)), 6, 12) + tw/2
							draw.SimpleTextOutlined("[", "jcms_small", ScrW()/2 - pulse, ScrH()/2 - (iOff-1)*th, clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, clr_dark)
							draw.SimpleTextOutlined("]", "jcms_small", ScrW()/2 + pulse, ScrH()/2 - (iOff-1)*th, clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, clr_dark)
						end
					else
						draw.SimpleText(orderName, "jcms_small", ScrW()/2, ScrH()/2 - (iOff-1)*th, clr_dark, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					end
				end
			end

			if jcms.hud_spawnmenuAnimScrollTip > 0.03 then
				local blend2 = math.ease.InOutCirc(jcms.hud_spawnmenuAnimScrollTip)
				surface.SetAlphaMultiplier(blend2)

				local tipx, tipy = ScrW()/2, ScrH() * 0.75
				surface.SetFont("jcms_medium")
				local tw, th = surface.GetTextSize("#jcms.orderscrolltip")

				surface.SetDrawColor(jcms.color_dark_alt)
				surface.DrawRect(tipx - tw/2 - 16, tipy - th/2 - 12, tw + 32, th + 24)

				surface.SetDrawColor(jcms.color_bright_alt)
				surface.DrawRect(tipx - tw/2, tipy - th/2 - 12, tw, 1)
				surface.DrawRect(tipx - tw/2, tipy + th/2 + 11, tw, 1)
				jcms.hud_DrawStripedRect(tipx-tw/2-16, tipy - th/2 - 12, 4, th + 24, 32, CurTime()%1 * 24)
				jcms.hud_DrawStripedRect(tipx+tw/2+16-4, tipy - th/2 - 12, 4, th + 24, 32, CurTime()%1 * 24)
				draw.SimpleText("#jcms.orderscrolltip", "jcms_medium", tipx, tipy, jcms.color_bright_alt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end

		surface.SetAlphaMultiplier(1)
		cam.End2D()
	end

-- // }}}

-- // Overrides {{{

	function jcms.spawnmenu_MakeMouseCapturePanel()
		if IsValid(jcms.spawnmenu_mouseCapturePanel) then
			jcms.spawnmenu_mouseCapturePanel:Remove()
		end

		local p = GetHUDPanel():Add("DPanel")
		function p:OnMouseWheeled(d)
			jcms.mousewheel = d
		end
		jcms.spawnmenu_mouseCapturePanel = p
		p:SetSize(ScrW(), ScrH())
		p:Center()
		p:SetPaintBackground(false)
		p:MakePopup()
		p:SetKeyboardInputEnabled(false)
		p:SetCursor("crosshair")
		p.Paint = jcms.spawnmenu_PaintMouseCapture
	end

	function GM:OnSpawnMenuOpen()
		if jcms.spawnmenu_isOpen then
			jcms.spawnmenu_isOpen = false
			jcms.spawnmenu_selectedOption = nil

			if IsValid(jcms.spawnmenu_mouseCapturePanel) then
				jcms.spawnmenu_mouseCapturePanel:Remove()
			end
		else
			local ply = LocalPlayer()
			
			if (ply:GetObserverMode() ~= OBS_MODE_NONE) then
				return
			else
			
				if jcms.team_JCorp_player(ply) then
					jcms.spawnmenu_isOpen = true
					jcms.spawnmenu_isContext = false
					jcms.spawnmenu_MakeMouseCapturePanel()
					surface.PlaySound("ambient/levels/citadel/pod_open1.wav")
				elseif jcms.team_NPC(ply) then
					RunConsoleCommand("jcms_order")
				end

			end
		end
	end

	function GM:OnSpawnMenuClose()
		--[[if not jcms.spawnmenu_isContext then
			jcms.spawnmenu_isOpen = false
			jcms.spawnmenu_selectedOption = nil
		end

		if IsValid(jcms.spawnmenu_mouseCapturePanel) then
			jcms.spawnmenu_mouseCapturePanel:Remove()
		end]]
	end

	function GM:OnContextMenuOpen()
		local ply = LocalPlayer()
		
		if (ply:GetObserverMode() ~= OBS_MODE_NONE) then
			return
		end
			
		if jcms.team_JCorp_player(ply) then
			jcms.spawnmenu_isOpen = true
			jcms.spawnmenu_isContext = true
			jcms.spawnmenu_MakeMouseCapturePanel()
		end
	end

	function GM:OnContextMenuClose()
		if jcms.spawnmenu_isContext then
			jcms.spawnmenu_isOpen = false

			if jcms.spawnmenu_selectedOption then
				surface.PlaySound("buttons/lightswitch2.wav")
				RunConsoleCommand("jcms_signal", tostring(jcms.spawnmenu_selectedOption))
				jcms.spawnmenu_selectedOption = nil
			end
		end

		if IsValid(jcms.spawnmenu_mouseCapturePanel) then
			jcms.spawnmenu_mouseCapturePanel:Remove()
		end
	end

-- // }}}
