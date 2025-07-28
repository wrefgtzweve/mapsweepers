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

-- Used as reference.
-- // Unrestricted {{{
	jcms.MAPGEN_CONSTRUCT_AREA = 59402361
	jcms.MAPGEN_CONSTRUCT_DENSITY = 1.157295952082

	jcms.MAPGEN_CONSTRUCT_AREART = 322817.33914096
	jcms.MAPGEN_CONSTRUCT_DENSITYRT = 34.8672226934
-- // }}}

-- // Restricted {{{
	jcms.MAPGEN_CONSTRUCT_AREA_RESTRICTED = 59294861
	jcms.MAPGEN_CONSTRUCT_DENSITY_RESTRICTED = 0.7195
	
	jcms.MAPGEN_CONSTRUCT_AREART_RESTRICTED = 106770
	jcms.MAPGEN_CONSTRUCT_DENSITYRT_RESTRICTED = 11.7614
-- // }}}

jcms.MAPGEN_CONSTRUCT_AVGAREASIZE = 345.53675117538
jcms.MAPGEN_CONSTRUCT_VOLUME = 359613
jcms.MAPGEN_CONSTRUCT_DIAMETER = math.sqrt(82411875)

-- // A* {{{

	function jcms.mapgen_Navigate(fromArea, toArea, cond)
		-- Rewritten from https://wiki.facepunch.com/gmod/Simple_Pathfinding

		if not (IsValid(fromArea) and IsValid(toArea)) then return false end
		if fromArea == toArea then return true, { fromArea } end

		fromArea:ClearSearchLists()
		fromArea:AddToOpenList()
		fromArea:SetCostSoFar(0)

		local camefrom = {}
		
		local function unwind()
			local current = toArea
			local total_path = { current }

			current = current:GetID()
			while camefrom[current] do
				current = camefrom[current]
				table.insert(total_path, navmesh.GetNavAreaByID(current))
			end

			return total_path
		end

		local function estimate(a, b)
			return a:GetCenter():Distance(b:GetCenter())
		end

		while not fromArea:IsOpenListEmpty() do
			local last = fromArea:PopOpenList()

			if last == toArea then
				return true, unwind()
			else
				last:AddToClosedList()

				local adjAreas = last:GetAdjacentAreas()
				
				for i, adj in ipairs(adjAreas) do
					if adj:IsDamaging() or adj:IsUnderwater() then continue end
					
					local newcost = last:GetCostSoFar() + estimate(last, adj)
					
					if cond and not cond(last, adj, newcost) then
						continue
					end
					
					if ( adj:IsOpen() or adj:IsClosed() ) and ( adj:GetCostSoFar() <= newcost ) then
						continue
					else
						adj:SetCostSoFar(newcost)
						adj:SetTotalCost(newcost + estimate(adj, toArea))

						if adj:IsOpen() then
							adj:UpdateOnOpenList()
						else
							adj:AddToOpenList()
						end

						camefrom[ adj:GetID() ] = last:GetID()
					end
				end
			end
		end

		return false
	end

-- // }}}

-- // Util {{{
	function jcms.mapgen_ValidArea(area)
		--Are we a trigger_hurt or underwater
		if jcms.mapdata and not(jcms.mapdata.validAreaDict[area] == nil) then return jcms.mapdata.validAreaDict[area] end --Optimisation, going to be using this func outside mapgen in future.
		if area:IsDamaging() or area:IsUnderwater() then return false end

		--Are we somehow inside a solid fucking block (conflux has this issue)
		local areaContents = util.PointContents( area:GetCenter() )
		local areaContentsAll = areaContents
		for i=1, 4, 1 do 
			local contents = util.PointContents( area:GetCorner(i-1) )
			areaContents = bit.band( contents, areaContents )
			areaContentsAll = bit.bor(contents, areaContentsAll)
		end

		--if ALL corners, and our centre are solid. Normal sane maps like construct have slanted navareas on small ledges, so we have to deal with that.
		if bit.band(areaContents, CONTENTS_SOLID) ~= 0 then 
			return false 
		end
		--If any of our points are touching a playerclip don't use it. Not reliable at all, but hopefully I'll fix that in the future.
		if bit.band(areaContentsAll, CONTENTS_PLAYERCLIP) ~= 0 then 
			return false
		end

		--Make sure we aren't on nodraw, because we can't reliably check if we're under a displacement due to static props.
		--Will also filter areas of the map that we're not meant to reach I suppose.
		local centre = area:GetCenter() + Vector(0,0,5)
		local floorCheck = util.TraceLine({
			start = centre,
			endpos = centre - Vector(0,0,10),
			mask = MASK_NPCSOLID_BRUSHONLY
		})

		if floorCheck.HitNoDraw then 
			return false
		end

		--Are we under a displacement? Traces pass through the back-side but not the top.
		local tr = util.TraceLine({
			start = centre,
			endpos = centre + Vector(0,0,32000), 
			mask = MASK_NPCSOLID_BRUSHONLY
		})

		if tr.HitNoDraw then --We've hit the bottom of a nodraw brush, and are probably under a road (or some other brush poking through a displacement)
			return false
		end
		
		local backTrace = util.TraceLine({
			start = tr.HitPos,
			endpos = centre,
			mask = MASK_NPCWORLDSTATIC
		})
		
		if centre:DistToSqr(backTrace.HitPos) > 5^2 then
			--todo: This stil fails for some valid navAreas. 
			--I am not sure whether this is floating point inaccuracy, or the raised centre genuinely still being underneath.
			return false 
		end

		return true 
	end

	function jcms.mapgen_CentreWeights( areasToCheck )
		local midAreaWeights = {}
		--local avgDepth = jcms.mapdata.areaDepthAvg
		for i, area in ipairs(areasToCheck or navmesh.GetAllNavAreas()) do
			--local depth = jcms.mapdata.areaDepths[area]
			--if depth and depth > avgDepth then
				local score = 1/jcms.mapgen_GetDistanceFromCenterRelative( area:GetCenter() )
				midAreaWeights[ area ] = score
			--end
		end
		return midAreaWeights
	end

	function jcms.mapgen_BorderWeights( areasToCheck )
		local borderAreaWeights = {}
		--local avgDepth = jcms.mapdata.areaDepthAvg
		for i, area in ipairs(areasToCheck or navmesh.GetAllNavAreas()) do 
			--local depth = jcms.mapdata.areaDepths[area]
			--if depth and depth > avgDepth then
				local score = jcms.mapgen_GetDistanceFromCenterRelative( area:GetCenter() )
				borderAreaWeights[ area ] = score
			--end
		end
		return borderAreaWeights
	end

	function jcms.mapgen_TryReadNodeData()
		ainReader.readNodeData()

		if not ainReader.nodePositions then return end 
		
		local md = jcms.mapdata
		md.nodeAreas = {}
		for i, nodePos in ipairs(ainReader.nodePositions) do 
			md.nodeAreas[nodePos] = jcms.mapgen_NearestArea(nodePos)
		end
	end

-- // }}

-- // Permanent data {{{

	jcms.mapdata = jcms.mapdata or { analyzed = false, vaild = false }

	function jcms.mapgen_AnalyzeMap()
		local md = jcms.mapdata
		local nav = navmesh.GetAllNavAreas()
		table.Shuffle(nav)
		
		md.areaCountUnrestricted = #nav
		md.areaCount = 0
		md.analyzed = true
		
		md.areaTotal = 0 -- Total area of all valid areas.
		md.areaTotalRT = 0 --Ditto, but the sum of roots of areas
		md.areaSpan = 0 -- Area (width*height) from top-left-most to bottom-right-most corner of valid portion of the map
		md.density = 0 -- Total/span.
		
		md.areaTotalUnrestricted = 0 -- Total area of ALL areas. Even invalid ones.
		md.areaTotalUnrestrictedRT = 0 --Ditto, but sum of roots of areas
		md.areaSpanUnrestricted = 0 -- Total navmesh span including invalid areas.
		md.densityUnrestricted = 0 -- Unr.total / unr.span

		md.avgAreaSizeRT = 0 --The average area of a navmesh area. 
		md.avgAreaSizeUnrestrictedRT = 0 --Ditto, but even invalid areas.
		
		md.vis = { avgAccumulator = 0 }
		md.visUnrestricted = { avgAccumulator = 0 }

		md.areaAreas = {}
		md.areaAreasUnrestricted = {}

		md.validAreas = {} --Table of all valid areas
		md.validAreaDict = {} --Dict for valid areas
		
		md.usefulness = 0 -- Tells us how much of the navmesh is actually valid. 0 = none, 1 = all of it.
		
		md.valid = md.areaCountUnrestricted > 1
		if md.valid then
			local depthAreaCounter = 0
			md.areaDepths = {}
			md.areaDepthAvg = 0
			md.areaDepthMax = 0
			
			md.sizedAreas = {
				huge = {},
				big = {},
				medium = {},
				small = {},
				tiny = {}
			}
			
			local minAreas = { tiny = 100^2, small = 250^2, medium = 450^2, big = 800^2, huge = 1250^2 }
			local allowedRatios = { tiny = 1.25, small = 1.5, medium = 1.8, big = 2.5, huge = 5 }
			local checkOrder = { "huge", "big", "medium", "small", "tiny" }
			local minDim = 50
			
			local xMin, yMin, xMax, yMax
			local xMinU, yMinU, xMaxU, yMaxU
			
			local areaZones = {}
		
			local function replacezones(from, to)
				for area, zone in pairs(areaZones) do
					if zone == from then
						areaZones[ area ] = to
					end
				end
			end
			
			for i, area in ipairs(nav) do
				local width, height = area:GetSizeX(), area:GetSizeY()
				md.areaAreasUnrestricted[area] = width*height
				md.areaTotalUnrestricted = md.areaTotalUnrestricted + md.areaAreasUnrestricted[area]
				md.areaTotalUnrestrictedRT = md.areaTotalUnrestrictedRT + math.sqrt(md.areaAreasUnrestricted[area])
				md.avgAreaSizeUnrestrictedRT = md.avgAreaSizeUnrestrictedRT + math.sqrt(md.areaAreasUnrestricted[area])
				
				local onborder = false
				for i=0, 3 do
					if area:GetAdjacentCountAtSide(i) <= 0 then
						onborder = true
						break
					end
				end
				
				if onborder then
					md.areaDepths[ area ] = 0
					depthAreaCounter = depthAreaCounter + 1
				end
				
				local v1, v2 = area:GetCorner(0), area:GetCorner(2)
				xMinU = math.min(xMinU or v1.x, v1.x, v2.x)
				xMaxU = math.max(xMaxU or v1.x, v1.x, v2.x)
				yMinU = math.min(yMinU or v1.y, v1.y, v2.y)
				yMaxU = math.max(yMaxU or v1.y, v1.y, v2.y)
				
				local areaVis = #area:GetVisibleAreas()
				md.visUnrestricted.min = math.min(md.visUnrestricted.min or areaVis, areaVis)
				md.visUnrestricted.max = math.max(md.visUnrestricted.max or areaVis, areaVis)
				md.visUnrestricted.avgAccumulator = md.visUnrestricted.avgAccumulator + areaVis
				
				md.validAreaDict[area] = jcms.mapgen_ValidArea(area)
				if not md.validAreaDict[area] then continue end
				table.insert(md.validAreas, area)
				
				local adj = area:GetAdjacentAreas()
				for j=#adj, 1, -1 do
					if not adj[j]:IsConnected(area) then
						table.remove(adj, j)
					end
				end
				
				local zoneAround = nil
				for j, oarea in ipairs(adj) do
					if oarea:IsUnderwater() or oarea:IsDamaging() then continue end
					
					if areaZones[oarea] then
						zoneAround = areaZones[oarea]
						break
					end
				end
				
				if zoneAround then
					areaZones[area] = zoneAround
					for j, oarea in ipairs(adj) do
						if oarea:IsUnderwater() or oarea:IsDamaging() then continue end
						if areaZones[oarea] and areaZones[oarea] ~= zoneAround then
							replacezones(areaZones[oarea], zoneAround)
						else
							areaZones[oarea] = zoneAround
						end
					end
				else
					local inZone = areaZones[area] or i
					
					for j, oarea in ipairs(adj) do
						if oarea:IsUnderwater() or oarea:IsDamaging() then continue end
						areaZones[oarea] = inZone
					end
				end
				
				if width < minDim or height < minDim then continue end
				
				local ratio = math.max(width, height) / math.min(width, height)
				for j, mag in ipairs(checkOrder) do
					if ( ratio < allowedRatios[mag] ) and (width*height >= minAreas[mag]) then
						md.areaAreas[area] = md.areaAreasUnrestricted[area]
						md.areaTotal = md.areaTotal + md.areaAreas[area]
						md.areaTotalRT = md.areaTotalRT + math.sqrt(md.areaAreas[area])
						md.avgAreaSizeRT = md.avgAreaSizeRT + math.sqrt(md.areaAreasUnrestricted[area])
						
						xMin = math.min(xMin or v1.x, v1.x, v2.x)
						xMax = math.max(xMax or v1.x, v1.x, v2.x)
						yMin = math.min(yMin or v1.y, v1.y, v2.y)
						yMax = math.max(yMax or v1.y, v1.y, v2.y)
						
						md.areaCount = md.areaCount + 1
						md.vis.min = math.min(md.vis.min or areaVis, areaVis)
						md.vis.max = math.max(md.vis.max or areaVis, areaVis)
						md.vis.avgAccumulator = md.vis.avgAccumulator + areaVis

						table.insert(md.sizedAreas[mag], area)
						break
					end
				end
			end
			
			local lastDepthWorkedWith = 0
			local depthAccumulator = 0
			repeat
				local foundOne = false
				
				for area, depth in pairs(md.areaDepths) do
					if depth == lastDepthWorkedWith then
						foundOne = true
						for i, oarea in ipairs( area:GetAdjacentAreas() ) do
							if not md.areaDepths[ oarea ] then
								depthAreaCounter = depthAreaCounter + 1
								depthAccumulator = depthAccumulator + (depth + 1)
								md.areaDepths[ oarea ] = depth + 1
							end
						end
					end
				end
				
				md.areaDepthMax = lastDepthWorkedWith
				if foundOne then
					lastDepthWorkedWith = lastDepthWorkedWith + 1
				else
					break
				end
			until (depthAreaCounter >= md.areaCountUnrestricted or lastDepthWorkedWith > 9999)
			
			if lastDepthWorkedWith > 9999 then
				print("area depth overflow... somehow? dev stats: ", depthAreaCounter, md.areaCountUnrestricted)
			end
			
			md.areaDepthAvg = depthAccumulator / depthAreaCounter
			
			md.vis.avg = md.vis.avgAccumulator / md.areaCount
			md.vis.avgAccumulator = nil
			
			md.visUnrestricted.avg = md.visUnrestricted.avgAccumulator / md.areaCount
			md.visUnrestricted.avgAccumulator = nil
			
			md.areaSpan = (xMax - xMin)*(yMax - yMin)
			md.areaSpanUnrestricted = (xMaxU - xMinU)*(yMaxU - yMinU)

			md.areaSpanRT = math.sqrt(md.areaSpan)
			md.areaSpanUnrestrictedRT = math.sqrt(md.areaSpanUnrestricted)
			
			md.density = md.areaTotal / md.areaSpan
			md.densityUnrestricted = md.areaTotalUnrestricted / md.areaSpanUnrestricted
			md.usefulness = md.areaTotal / md.areaTotalUnrestricted

			md.densityRT = md.areaTotalRT / md.areaSpanRT
			md.densityUnrestrictedRT = md.areaTotalUnrestrictedRT / md.areaSpanUnrestrictedRT

			md.avgAreaSizeRT = md.avgAreaSizeRT / md.areaCount
			md.avgAreaSizeUnrestrictedRT = md.avgAreaSizeUnrestrictedRT / #nav
			
			md.navmeshSpan = { xMin, yMin, xMax, yMax }
			md.navmeshSpanUnrestricted = { xMinU, yMinU, xMaxU, yMaxU }
			
			local zoneList = {}
			local translation = {}
			local zindex = 0
			
			for area, zone in pairs(areaZones) do
				if area:IsUnderwater() or area:IsDamaging() then continue end

				if not translation[zone] then
					zindex = zindex + 1
					translation[zone] = zindex
				end
				
				local trzone = translation[zone]
				if not zoneList[trzone] then
					zoneList[trzone] = { area }
				else
					table.insert(zoneList[trzone], area)
				end
			end
			
			table.sort(zoneList, function(first, last)
				return #first > #last
			end)
			
			local zoneDict = {}
			local zoneAreaSizes = {}
			local largestId = -1
			local largestSize = 0 
		
			for zoneId, areas in ipairs(zoneList) do
				local totalArea = 0
				for j, area in ipairs(areas) do
					zoneDict[area] = zoneId
					totalArea = totalArea + area:GetSizeX() * area:GetSizeY()
				end
				zoneAreaSizes[zoneId] = totalArea
				if largestSize < totalArea then 
					largestId = zoneId
					largestSize = totalArea
				end
			end
			
			jcms.mapdata.zoneList = zoneList
			jcms.mapdata.zoneDict = zoneDict
			jcms.mapdata.zoneSizes = zoneAreaSizes
			jcms.mapdata.largestZone = largestId
		end

		md.volumeTotal = 0 --Total volume of all visleaves
		for i=1, #bspReader.leafMins, 1 do 
			if bspReader.leafClusterConnections[i-1] and not(bspReader.getVisLeafArea( i-1 ) == jcms.pathfinder.skyArea) then --Hacky check for if we're in the map.
				local mins, maxs = bspReader.getVisLeafBounds( i-1 )
				local minX, minY, minZ = mins:Unpack()
				local maxX, maxY, maxZ = maxs:Unpack()

				local vol = ( (maxX - minX) * (maxY - minY) * (maxZ - minZ) ) ^ (1/3)
				md.volumeTotal = md.volumeTotal + vol
			end
		end

		if not ainReader.nodePositions then 
			ainReader.readNodeData()
		end

		jcms.mapgen_TryReadNodeData()

		if md.areaCount <= 1 then
			md.valid = false
		end
	end

	function jcms.mapgen_ExpandedAreaList(areas)
		local handledAreas = {}
		local expandedAreas = {}

		for i, area in ipairs(areas) do
			if not handledAreas[area] then
				handledAreas[area] = true
				table.insert(expandedAreas, area)

				local adjAreas = navmesh.Find(area:GetCenter(), (area:GetSizeX() + area:GetSizeY())/2 + 400, 300, 300)
				for j, adjArea in ipairs(adjAreas) do
					if not handledAreas[adjArea] then
						handledAreas[adjArea] = true
						table.insert(expandedAreas, adjArea)
					end
				end
			end
		end

		return expandedAreas
	end

	function jcms.mapgen_SubdivideAreasIntoVectors(areas, subdiv)
		local vectors = {}

		subdiv = math.max(tonumber(subdiv) or 2, 2)
		for i, area in ipairs(areas) do
			local xSubdivCount = math.ceil(area:GetSizeX() / subdiv)
			local ySubdivCount = math.ceil(area:GetSizeY() / subdiv)

			for x=1, xSubdivCount do
				for y=1, ySubdivCount do
					local v = area:GetCorner(0)
					v.x = xSubdivCount==1 and (v.x + area:GetSizeX()/2) or (v.x + subdiv * (x-1))
					v.y = ySubdivCount==1 and (v.y + area:GetSizeY()/2) or (v.y + subdiv * (y-1))
					v.z = area:GetZ(v)
					
					if bit.band(util.PointContents(v), CONTENTS_SOLID) == 0 then
						table.insert(vectors, v)
					end
				end
			end
		end

		return vectors
	end

	function jcms.mapgen_VectorGrid(areas, subdivisionSize, connectionDist)	
		local chunks, chunksize, getChunkId, getChunkTable, getAllNearbyNodes = jcms.util_ChunkFunctions(512)
		
		subdivisionSize = math.max( 1, tonumber(subdivisionSize) or 128 )
		connectionDist = math.max(1, tonumber(connectionDist) or subdivisionSize * 1.9)
		assert( connectionDist < subdivisionSize * 4, "[jcms.mapgen_VectorGrid] Connection distance is too high, your PC wouldn't like it." )

		local subdiv = subdivisionSize
		local connectionDist2 = connectionDist * connectionDist
		for i, area in ipairs(areas) do
			local xSubdivCount = math.ceil(area:GetSizeX() / subdiv)
			local ySubdivCount = math.ceil(area:GetSizeY() / subdiv)

			for x=1, xSubdivCount do
				for y=1, ySubdivCount do
					local v = area:GetCorner(0)
					v.x = xSubdivCount==1 and (v.x + area:GetSizeX()/2) or (v.x + subdiv * (x-1))
					v.y = ySubdivCount==1 and (v.y + area:GetSizeY()/2) or (v.y + subdiv * (y-1))
					v.z = area:GetZ(v)
					if bit.band(util.PointContents(v), CONTENTS_SOLID) == 0 then
						table.insert(getChunkTable(v.x, v.y, v.z), v)
					end
				end
			end
		end

		--todo: Auto-connect within our area, 
		--Auto connect the extreme-edges of navareas to adjacent ones.

		local tr_res = {}
		local tr_data = { 
			mask = MASK_PLAYERSOLID_BRUSHONLY, 
			output = tr_res
		}

		local connections = {}
		for chunkId, chunk in pairs(chunks) do
			local n = chunk[1]
			if n then
				local nodes = getAllNearbyNodes(n.x, n.y, n.z)
				for i, pt in ipairs( nodes ) do
					for oi=1, i-1 do
						local opt = nodes[oi]
						local dist2 = opt:DistToSqr(pt)

						if dist2 >= (subdiv*subdiv - 16) then
							local zDiminishDist2 = (pt.x - opt.x)^2 + (pt.y - opt.y)^2 + ((pt.z - opt.z)*0.25)^2
							
							if zDiminishDist2 <= connectionDist2 then
								tr_data.start = Vector( pt.x, pt.y, pt.z + subdiv/2)
								tr_data.endpos = Vector( opt.x, opt.y, opt.z + subdiv )
								util.TraceLine(tr_data)

								if not tr_res.Hit then
									if not connections[pt] then
										connections[pt] = { opt }
									else
										table.insert(connections[pt], opt)
									end

									if not connections[opt] then
										connections[opt] = { pt }
									else
										table.insert(connections[opt], pt)
									end
								end
							end
						end
					end
				end
			end
		end

		for chunkId, chunk in pairs(chunks) do
			if #chunk == 0 then
				chunks[chunkId] = nil
			end
		end

		return connections, chunks
	end

	function jcms.mapgen_WallTraces(tr_count, tr_dist, tr_data)
		local outputTraces = {}

		for j = 1, tr_count do
			local ang = math.pi * 2 / tr_count * j
			local cos, sin = math.cos(ang), math.sin(ang)
			tr_data.endpos = Vector(tr_data.start.x + cos * tr_dist, tr_data.start.y + sin * tr_dist, tr_data.start.z)
			local tr = util.TraceHull(tr_data)
			table.insert(outputTraces, tr)
		end

		return outputTraces
	end

	function jcms.mapgen_VectorGridCosts_WallProximity(connections, chunks, traceDist, wallCostMultiplier, inverseCost)
		wallCostMultiplier = tonumber(wallCostMultiplier) or 1

		local costs = {}

		local tr_dist = tonumber(traceDist) or 100
		local tr_count = 8
		local tr_data = { 
			mins = Vector(-24, -24, -8), 
			maxs = Vector(24, 24, 8), 
			mask = MASK_PLAYERSOLID_BRUSHONLY
		}

		for chunkId, chunk in pairs(chunks) do
			for i, pt in ipairs(chunk) do
				local weight = 1
				tr_data.start = Vector( pt.x, pt.y, pt.z + 64 )

				for i, tr in ipairs(jcms.mapgen_WallTraces(tr_count, tr_dist, tr_data)) do 
					weight = math.min(weight, tr.Fraction)
				end

				costs[pt] = (inverseCost and (1 - weight) or weight) * wallCostMultiplier
			end
		end

		return costs
	end

	function jcms.mapgen_OptimiseVectorPath( vectorPath )
		if not(#vectorPath > 1) then return end

		local lineStart = #vectorPath
		local lineEnd = #vectorPath
		local currentDir = (vectorPath[#vectorPath] - vectorPath[#vectorPath-1]):GetNormalized()

		for i=#vectorPath, 1, -1 do 
			local vec1 = vectorPath[i]
			local vec2 = vectorPath[i-1]
			if not vec2 then continue end 

			local dirVec = vec1 - vec2
			dirVec:Normalize()

			if dirVec:IsEqualTol(currentDir, 0.025) then --approximately equal.
				lineEnd = i
			else
				for i=lineStart - 1, lineEnd, -1 do 
					table.remove(vectorPath, i)
				end

				currentDir = dirVec
				lineStart = i
			end
		end

	end

	function jcms.mapgen_GenPathAround(areas, traceDist, wallCostMultiplier)
		local connections, chunks = jcms.mapgen_VectorGrid(areas, math.Rand(0.0220, 0.0280) * 6000)
		local costs = jcms.mapgen_VectorGridCosts_WallProximity(connections, chunks, traceDist or 256, tonumber(wallCostMultiplier) or 15000, true)

		local bestPath = nil
		local bestPathLength = 0
		
		local minCost = math.huge
		local sumCost = 0
		local pointsCount = 0
		for pt in pairs(connections) do
			minCost = math.min( minCost, costs[pt] )
			sumCost = sumCost + costs[pt]
			pointsCount = pointsCount + 1
		end
		local avgCost = sumCost / pointsCount 

		local allPoints = {}
		for pt in pairs(connections) do
			if costs[ pt ] <= (minCost*5 + avgCost)/6 then
				table.insert(allPoints, pt)
			end 
		end

		if #allPoints > 1 then

			local T1 = SysTime()
			for i, pt in ipairs(allPoints) do
				local oi
				repeat
					oi = math.random(1, #allPoints)
				until ( oi ~= i )
				local opt = allPoints[oi]

				local path = jcms.pathfinder.navigateVectorGrid(connections, costs, pt, opt)
				local pathLength = 0

				if path then
					for j=1, #path-1 do
						local v1, v2 = path[j], path[j+1]
						pathLength = pathLength + v1:Distance(v2)
					end
				end

				if pathLength > bestPathLength then
					bestPath = path
					bestPathLength = pathLength
				end

				if bestPath then
					break
				end
			end

			timer.Simple(0.5, function()
				if bestPath then
					for j=1, #bestPath-1 do
						local v1, v2 = bestPath[j], bestPath[j+1]
						debugoverlay.Line(v1, v2, 5, HSVToColor(j/#bestPath*360, 0.8, 1), true)
					end
				end
			end)

			return bestPath, bestPathLength
		end
	end
	
	function jcms.mapgen_DemonstrateList(list)
		if type(list) == "table" then
			timer.Simple(0.5, function()
				local u = Vector(0, 0, 4)
				local n = #list
				for i, area in ipairs(list) do
					local col = HSVToColor(i/n*360, 0.75, 0.9)
					debugoverlay.Triangle(area:GetCorner(2)+u, area:GetCorner(1)+u, area:GetCorner(0)+u, 3, col)
					debugoverlay.Triangle(area:GetCorner(2)+u, area:GetCorner(0)+u, area:GetCorner(3)+u, 3, col)
				end
			end)
		end
	end

	function jcms.mapgen_DemonstrateNavmeshDepths()
		timer.Simple(0.5, function()
			local u = Vector(0, 0, 4)
			local maxDepth = jcms.data.areaDepthMax
			local avgDepth = jcms.mapdata.areaDepthAvg
			for area, depth in pairs(jcms.mapdata.areaDepths) do
				local col = HSVToColor(depth/maxDepth*240, 0.75, depth > avgDepth and 1 or 0.5)
				debugoverlay.Triangle(area:GetCorner(2)+u, area:GetCorner(1)+u, area:GetCorner(0)+u, 3, col)
				debugoverlay.Triangle(area:GetCorner(2)+u, area:GetCorner(0)+u, area:GetCorner(3)+u, 3, col)
			end
		end)
	end
	
	function jcms.mapgen_DemonstrateNavmeshVis()
		timer.Simple(0.5, function()
			local u = Vector(0, 0, 4)
			local minVis, maxVis = jcms.mapdata.visUnrestricted.min, jcms.mapdata.visUnrestricted.max
			
			for i, area in ipairs(navmesh.GetAllNavAreas()) do
				local col = HSVToColor(math.Remap(#area:GetVisibleAreas(), minVis, maxVis, 0, 240), 0.7, 1)
				debugoverlay.Triangle(area:GetCorner(2)+u, area:GetCorner(1)+u, area:GetCorner(0)+u, 3, col)
				debugoverlay.Triangle(area:GetCorner(2)+u, area:GetCorner(0)+u, area:GetCorner(3)+u, 3, col)
			end
		end)
	end
	
	function jcms.mapgen_DemonstrateNavmeshDistFromCenter()
		timer.Simple(0.5, function()
			local u = Vector(0, 0, 4)
			local minX, minY, maxX, maxY = jcms.mapgen_GetNavmeshSpan()
			local cx, cy = (minX+maxX)/2, (minY+maxY)/2
			local maxDist = 0
			
			for i, area in ipairs(navmesh.GetAllNavAreas()) do
				local c = area:GetCenter()
				maxDist = math.max( maxDist, math.Distance(c.x, c.y, cx, cy) )
			end
			
			for i, area in ipairs(navmesh.GetAllNavAreas()) do
				local c = area:GetCenter()
				local col = HSVToColor(math.Distance(c.x, c.y, cx, cy)/maxDist*360, 0.7, 1)
				debugoverlay.Triangle(area:GetCorner(2)+u, area:GetCorner(1)+u, area:GetCorner(0)+u, 3, col)
				debugoverlay.Triangle(area:GetCorner(2)+u, area:GetCorner(0)+u, area:GetCorner(3)+u, 3, col)
			end
		end)
	end
	
	function jcms.mapgen_GetNavmeshSpan(unrestricted) -- Mins/maxs of the navmesh.
		if unrestricted then
			if not jcms.mapdata.navmeshSpanUnrestricted then
				jcms.mapgen_AnalyzeMap()
			end

			return unpack(jcms.mapdata.navmeshSpanUnrestricted)
		else
			if not jcms.mapdata.navmeshSpan then
				jcms.mapgen_AnalyzeMap()
			end
			
			return unpack(jcms.mapdata.navmeshSpan)
		end
	end

	function jcms.mapgen_GetAreaSpan(unrestricted) -- The "area" of the navmesh span.
		if unrestricted then
			if not jcms.mapdata.areaSpanUnrestricted then
				jcms.mapgen_AnalyzeMap()
			end

			return jcms.mapdata.areaSpanUnrestricted
		else
			if not jcms.mapdata.areaSpan then
				jcms.mapgen_AnalyzeMap()
			end

			return jcms.mapdata.areaSpan
		end
	end
	
	function jcms.mapgen_GetDistanceFromCenter(pos, squared, unrestricted)
		local xMin, yMin, xMax, yMax = jcms.mapgen_GetNavmeshSpan(unrestricted)
		
		if squared then
			return math.DistanceSqr( pos.x, pos.y, (xMin+xMax)/2, (yMin+yMax)/2 )
		else
			return math.Distance( pos.x, pos.y, (xMin+xMax)/2, (yMin+yMax)/2 )
		end
	end
	
	function jcms.mapgen_GetDistanceFromCenterRelative(pos, unrestricted)
		local xMin, yMin, xMax, yMax = jcms.mapgen_GetNavmeshSpan(unrestricted)
		local maxDist = math.Distance( (xMin+xMax)/2, (yMin+yMax)/2, xMin, yMin )
		return math.Distance( pos.x, pos.y, (xMin+xMax)/2, (yMin+yMax)/2 ) / maxDist
	end

	function jcms.mapgen_GetSizedAreas()
		if not jcms.mapdata.sizedAreas then
			jcms.mapgen_AnalyzeMap()
		end
		
		return jcms.mapdata.sizedAreas
	end
	
	function jcms.mapgen_GetVisData(unrestricted)
		if unrestricted then
			if not jcms.mapdata.visUnrestricted then
				jcms.mapgen_AnalyzeMap()
			end
			
			return jcms.mapdata.visUnrestricted
		else
			if not jcms.mapdata.vis then
				jcms.mapgen_AnalyzeMap()
			end
			
			return jcms.mapdata.vis
		end
	end

	function jcms.mapgen_GetAreaAreas(unrestricted)
		if unrestricted then
			if not jcms.mapdata.areaAreasUnrestricted then
				jcms.mapgen_AnalyzeMap()
			end

			return jcms.mapdata.areaAreasUnrestricted
		else
			if not jcms.mapdata.areaAreas then
				jcms.mapgen_AnalyzeMap()
			end

			return jcms.mapdata.areaAreas
		end
	end

	function jcms.mapgen_GetMapSizeMultiplier()
		local md = jcms.mapdata
		if not md.areaTotalUnrestricted then
			jcms.mapgen_AnalyzeMap()
		end

		--Area mult, volume mult
		local areaMult = md.areaTotalUnrestrictedRT / jcms.MAPGEN_CONSTRUCT_AREART
		local volumeMult = md.volumeTotal/ jcms.MAPGEN_CONSTRUCT_VOLUME
		local densityMult = md.densityUnrestrictedRT / jcms.MAPGEN_CONSTRUCT_DENSITYRT
		local avgAreaMult = md.avgAreaSizeRT / jcms.MAPGEN_CONSTRUCT_AVGAREASIZE

		return areaMult, volumeMult, densityMult, avgAreaMult
	end
	
	function jcms.mapgen_GetMapSizeMultiplier_Restricted() --Restricted versions
		local md = jcms.mapdata
		if not md.areaTotal then
			jcms.mapgen_AnalyzeMap()
		end

		local areaMult = md.areaTotalRT / jcms.MAPGEN_CONSTRUCT_AREART_RESTRICTED
		local volumeMult = md.volumeTotal/ jcms.MAPGEN_CONSTRUCT_VOLUME
		local densityMult = md.densityRT / jcms.MAPGEN_CONSTRUCT_DENSITYRT_RESTRICTED
		local avgAreaMult = md.avgAreaSizeRT / jcms.MAPGEN_CONSTRUCT_AVGAREASIZE

		return areaMult, volumeMult, densityMult, avgAreaMult
	end

	function jcms.mapgen_AdjustCountForMapSize(count)
		local sizeMul = jcms.mapgen_GetMapSizeMultiplier()
		return math.floor( count * math.max(1, sizeMul^0.8) )
	end
	
-- // }}}

-- // Area Functions {{{

	function jcms.mapgen_UseRandomArea(priorityOrder)
		local sizedAreas = jcms.mapgen_GetSizedAreas()
		
		if priorityOrder then
			for i, size in ipairs(priorityOrder) do
				local v, k = table.Random(sizedAreas[ size ])
				if v and k then
					return v, k, size
				end
			end
		else
			local sizeWeights = {}

			for size, subtable in pairs(sizedAreas) do
				sizeWeights[ size ] = #subtable
			end

			local size = jcms.util_ChooseByWeight(sizeWeights)
			local v, k = table.Random(sizedAreas[ size ])
			if v and k then
				return v, k, size
			end
		end
	end

	function jcms.mapgen_AreaPointAwayFromEdges(a, distance)
		local sx, sy = a:GetSizeX(), a:GetSizeY()
		distance = math.Clamp( tonumber(distance) or 64, 0, math.min(sx, sy) )

		local center = a:GetCenter()
		center.x = center.x + (sx - distance*2) * (math.random() - 0.5)
		center.y = center.y + (sy - distance*2) * (math.random() - 0.5)
		return a:GetClosestPointOnArea(center)
	end

	function jcms.mapgen_NearestArea(pos) --Similar to GetNearestNavArea but only using valid ones.
		local closest = nil
		local closestDist = math.huge
		for i, area in ipairs(jcms.mapdata.validAreas) do 
			local dist = pos:DistToSqr(area:GetCenter())
			if dist < closestDist then 
				closest = area
				closestDist = dist
			end
		end
		return closest, closestDist
	end

	function jcms.mapgen_GetAreaEdgePos(navArea, edge)
		local c1 = navArea:GetCorner( edge ) 
		local c2 = navArea:GetCorner( (edge + 1)%4 )
		return (c1 + c2)/2 
	end

	function jcms.mapgen_DropEntToNav(ent, pos) --More reliable :DropToFloor. Don't use on npcs/non-statics as they could fall through a displacement.
		pos = pos or ent:GetPos()
		local nearestArea = navmesh.GetNearestNavArea(pos, false, 250, true, true)
		if not IsValid(nearestArea) then return end
		ent:SetPos( nearestArea:GetClosestPointOnArea(pos) )
	end

-- // }}}

-- // Distribution {{{

	function jcms.mapgen_DistributePOIs(n, rad, weighedAreas)
		weighedAreas = weighedAreas or jcms.mapgen_GetAreaAreas()
		local shuffled = jcms.util_GetShuffledByWeight(weighedAreas)

		rad = tonumber(rad) or math.sqrt(jcms.mapgen_GetAreaSpan()*0.3)/math.sqrt(n)
		local rad2 = rad*rad
		local bestSolution = {}

		local startTime = SysTime()
		for iteration, startingArea in ipairs(shuffled) do
			local solution = { jcms.mapgen_AreaPointAwayFromEdges(startingArea, 64) }

			for i=1, math.ceil(#shuffled/2) + 1 do
				local area = jcms.util_ChooseByWeight(weighedAreas)
				local areaArea = area:GetSizeX() * area:GetSizeY()
				local attempts = math.Clamp(math.ceil( math.sqrt(areaArea) / 150 ), 1, 16)

				for j=1, attempts do
					local v = jcms.mapgen_AreaPointAwayFromEdges(area, 64)
					local good = true
					for k, ov in ipairs(solution) do
						if v:DistToSqr(ov) < rad2 then
							good = false
							break
						end
					end

					if good then
						table.insert(solution, v)

						if #solution >= n then
							break
						end
					end
				end

				if #solution >= n then
					break
				end
			end

			if (#solution == n) or (SysTime() - startTime) > 1 then
				bestSolution = solution
				break
			elseif #solution > #bestSolution then
				table.Empty(bestSolution)
				table.Add(bestSolution, solution)
			end
		end

		timer.Simple(0.5, function()
			for i,v in ipairs(bestSolution) do
				debugoverlay.Cross(v, 64, 1, Color(255,0,0), true)
				debugoverlay.Cross(v, 128, 1, Color(0,255,0), true)
			end
		end)

		return bestSolution
	end

-- // }}}

-- // Map Gen {{{

	function jcms.mapgen_PlaceNaturals(maxcount, weightOverride)
		local naturalWeights = jcms.prefab_GetNaturalTypesWithWeights()

		if isfunction(weightOverride) then
			for name, weight in pairs(naturalWeights) do 
				naturalWeights[name] = weightOverride(name, weight)
			end
		end

		local naturalCounts = {}
		local allAreas = {}
		for i, area in ipairs( jcms.mapdata.validAreas ) do
			if not ( area:GetSizeX() < 48 or area:GetSizeY() < 48 or area:IsDamaging() or bit.band( area:GetAttributes(), bit.bor(NAV_MESH_AVOID, NAV_MESH_OBSTACLE_TOP) ) > 0 ) then
				table.insert( allAreas, area )
			end
		end
		
		local canHouse = {}
		
		local zoneDict = jcms.mapgen_ZoneDict()
		for i, area in ipairs(allAreas) do
			canHouse[area] = {}

			for naturaltype in pairs(naturalWeights) do
				local prefabData = jcms.prefabs[naturaltype]
				if not(prefabData.onlyMainZone and not(zoneDict[area] == jcms.mapdata.largestZone)) then 
					local can, bonusData = jcms.prefab_Check(naturaltype, area)
					if can then
						table.insert( canHouse[area], { naturaltype, bonusData } )
					end
				end
			end
		end
		
		local stamped = 0
		local mapSizeMul = jcms.mapgen_GetMapSizeMultiplier_Restricted()

		local function calcw(area, prefabType)
			for i, tuple in ipairs(canHouse[area]) do
				if tuple[1] == prefabType then
					return 1 / #canHouse[area]
				end
			end
			return 0
		end

		for i=1, maxcount do
			local prefabType
			while true do
				prefabType = jcms.util_ChooseByWeight(naturalWeights)

				local prefabData = jcms.prefabs[prefabType]
				if prefabData.limit and (naturalCounts[prefabType] or 0) >= (isfunction(prefabData.limit) and prefabData.limit() or prefabData.limit) * math.Round(prefabData.limitMulBySize and mapSizeMul or 1) then
					naturalWeights[prefabType] = nil
				else
					break
				end
			end

			if not prefabType then
				break
			end

			local weighedAreas = {}
			for j, area in ipairs(allAreas) do
				local w = calcw(area, prefabType)
				if w > 0 then
					weighedAreas[area] = w
				end
			end

			local chosenArea = jcms.util_ChooseByWeight(weighedAreas)
			if chosenArea then
				for j, tuple in ipairs(canHouse[chosenArea]) do
					if tuple[1] == prefabType then
						jcms.prefab_ForceStamp(prefabType, chosenArea, tuple[2])
						stamped = stamped + 1
						
						naturalCounts[prefabType] = (naturalCounts[prefabType] or 0) + 1
 						break
					end
				end
			else
				break
			end
		end

		jcms.printf("Stamped prefabs: %d", stamped)
	end
	
	function jcms.mapgen_PlaceEncounters()
		local d = assert(jcms.director, "director is not running, can't place encounters")
		d.encounters = d.encounters or {}
		
		local sizedAreas = jcms.mapgen_GetSizedAreas()
		local visData = jcms.mapgen_GetVisData()
		
		local chances = {
			huge = 0.95,
			big = 0.74,
			medium = 0.38,
			small = 0.12,
			tiny = 0.02
		}
		
		local delays = {
			huge = 5,
			big = 4,
			medium = 3,
			small = 2,
			tiny = 1
		}
		
		if visData and (visData.max <= 4 or visData.avg <= 2) then -- This is a pretty shitty situation to be in.
			visData = nil
		end
		
		local stamped = 0
		local difficultyChanceMul = (jcms.runprogress_GetDifficulty() + 1.8) / 3
		for size, areas in pairs(sizedAreas) do
			for i, area in ipairs(areas) do
				local chance = chances[size]
				
				if visData then
					local vis = #area:GetVisibleAreas()
					local aavg = (visData.avg + visData.min)/2
					if vis < aavg then
						chance = math.Remap(vis, visData.min, aavg, math.max(chance*1.1, 0.25), chance)
					elseif vis < visData.avg then
						chance = math.Remap(vis, aavg, visData.avg, chance, chance*0.6)
					else
						chance = math.Remap(vis, visData.avg, visData.max, chance*0.6, chance*0.3)
					end
				end
				
				if math.random() < chance * difficultyChanceMul then
					local sx, sy = area:GetSizeX(), area:GetSizeY()
					
					local v = area:GetCenter()
					v.z = v.z + 32
					
					table.insert(d.encounters, {
						pos = v,
						rad = math.max(math.sqrt(sx*sx + sy*sy) + 20, 250),
						npcCount = math.ceil( math.ceil((sx + sy)/(512))^1.28 ) + 1,
						delay = delays[size] + math.random()
					})
					
					stamped = stamped + 1
				end
			end
		end
		
		jcms.printf("Encounters placed: %d", stamped)
	end
	
	function jcms.mapgen_FromMission(mission)
		assert(type(mission) == "table" and mission.faction and mission.generate, "invalid mission data, must be a table")
		local missionData = {} -- Put various entities and persistent mission data in here.
		mission:generate(missionData)
		jcms.director.missionData = missionData
	end

-- // }}}

-- // Zones {{{

	function jcms.mapgen_ZoneList()
		if not jcms.mapdata.zoneList then
			jcms.mapgen_AnalyzeMap()
		end
		
		return jcms.mapdata.zoneList
	end
	
	function jcms.mapgen_ZoneDict()
		if not jcms.mapdata.zoneDict then
			jcms.mapgen_AnalyzeMap()
		end
		
		return jcms.mapdata.zoneDict
	end

-- // }}}

-- // Shared Generation Behaviours. {{{

	function jcms.mapgen_SpreadPrefabs(type, count, sizeXY, onlyMainZone)
		local pref = jcms.prefabs[type]

		local zoneDict = jcms.mapgen_ZoneDict()

		-- // Initial weights {{{
			local defaultWeightedAreas = {}
			for i, area in ipairs(jcms.mapdata.validAreas) do 
				if not(onlyMainZone and not(zoneDict[area] == jcms.mapdata.largestZone)) and area:GetSizeX() > sizeXY and area:GetSizeY() > sizeXY and pref.check(area) then 
					defaultWeightedAreas[area] = math.sqrt(area:GetSizeX() * area:GetSizeY())
				end
			end
		-- // }}}

		local prefabAreas = {}
		local prefabs = {}

		--Optimisation
		local upVec = Vector(0, 0, 190)
		local area_vectors = {}
		local area_raisedVectors = {}
		for area, weight in pairs(defaultWeightedAreas) do 
			area_vectors[area] = area:GetCenter()
			area_raisedVectors[area] = area:GetCenter() + upVec
		end

		for i=1, count, 1 do
			local weightedAreas = {}
			for area, weight in pairs(defaultWeightedAreas) do 
				local closestDist = math.huge
				local canSeeOther = false

				for i, otherArea in ipairs(prefabAreas) do --Don't spawn too close to others.
					local dist = area_vectors[area]:Distance( area_vectors[otherArea] )
					closestDist = (closestDist < dist and closestDist) or dist
					canSeeOther = canSeeOther or otherArea:IsPartiallyVisible( area_raisedVectors[area] )
				end
				
				if not(closestDist == math.huge) then  
					weight = weight * math.sqrt(closestDist)
				end
				if canSeeOther then 
					weight = weight * 0.00001
				end
				weightedAreas[area] = weight
			end

			local chosenArea = jcms.util_ChooseByWeight(weightedAreas)

			if not chosenArea then return prefabs end --Fail safe (map has no or not enough valid areas)

			local worked, pref = jcms.prefab_TryStamp(type, chosenArea) --We've already checked if our target area is valid, no need to check again
			table.insert(prefabAreas, chosenArea) 
			table.insert(prefabs, pref)
		end

		return prefabs
	end
-- // }}}