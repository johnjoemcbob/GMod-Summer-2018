--
-- Prickly Summer 2018
-- 03/06/18
--
-- Level Generation
--

local DEBUG						= true
local PRK_GEN_COLLIDE_ALL		= false
local PRK_GEN_DONT				= 4000
local PRK_GEN_DONT_SIZEMULT		= 1 / PRK_Gen_SizeModifier
local PRK_GEN_COLLISION_BORDER	= 90 / 100

local PRK_GEN_TYPE_FLOOR	= 1
local PRK_GEN_TYPE_WALL		= 2
local PRK_GEN_TYPE_CEILING	= 3

PRK_GEN_TYPE_MAT = {}
PRK_GEN_TYPE_MAT[PRK_GEN_TYPE_FLOOR]	= "models/rendertarget" -- "phoenix_storms/bluemetal"
PRK_GEN_TYPE_MAT[PRK_GEN_TYPE_WALL]		= "prk_gradient" -- "phoenix_storms/dome"
PRK_GEN_TYPE_MAT[PRK_GEN_TYPE_CEILING]	= "models/rendertarget" -- "phoenix_storms/metalset_1-2"

local size = PRK_Plate_Size
local hsize = size / 2

local HelperModels = {
	Anchor = {
		Model = "models/props_c17/pulleyhook01.mdl",
		Angle = Angle( 180, 0, 0 ),
	},
	Attach = {
		Model = "models/props_junk/PushCart01a.mdl",
		Angle = Angle( 0, 0, 0 ),
	},
	-- Min = {
		-- Model = "models/mechanics/solid_steel/l-beam__16.mdl",
		-- Angle = Angle( 0, 0, 0 ),
	-- },
	-- Max = {
		-- Model = "models/hunter/tubes/tube2x2x+.mdl",
		-- Angle = Angle( 0, 0, 0 ),
	-- },
}

local SpawnEditorEnt = {}
SpawnEditorEnt["Vendor"] = function( pos, ang, scale, model )
	local ent = PRK_CreateEnt( "prk_uimachine", nil, pos, ang )
	return ent
end
SpawnEditorEnt["Spawner"] = function( pos, ang, scale, model )
	local ent = PRK_CreateEnt( table.Random( PRK_Enemy_Types ), nil, pos, Angle( 0, math.random( 0, 360 ), 0 ) )
	return ent
end
SpawnEditorEnt["Rock"] = function( pos, ang, scale, model )
	local ent = PRK_CreateEnt( "prk_rock", nil, pos, Angle( 0, math.random( 0, 360 ), 0 ) )
	return ent
end
SpawnEditorEnt["Prop"] = function( pos, ang, scale, model )
	print( "prop ay" )
	local ent = PRK_CreateEnt( "prop_physics", model, pos, ang )
		ent:SetModelScale( scale )
		ent:SetMaterial( "models/debug/debugwhite" )
	return ent
end

local LastGen = {} -- Table of all rooms last generated
local ToGen = {} -- Table of rooms still to try attach points for
local CurrentRoomID = 0 -- Indices for rooms
local room

concommand.Add( "prk_gen", function( ply, cmd, args )
	PRK_Gen_Remove()
	PRK_Gen( ply:GetPos() - Vector( 0, 0, 100 ), 1 )
end )

local rooms, starts, finishes
function PRK_Gen( origin, zone )
	LastGen = {}
	CurrentRoomID = 0

	-- Create each helper model entity
	for k, v in pairs( HelperModels ) do
		local ent = PRK_CreateProp( v.Model, origin, v.Angle )
		v.Ent = ent
	end

	-- Load rooms
	rooms = PRK_Gen_LoadRooms()

	-- Remove default navmeshes
	navmesh.Reset()

	-- Generate first room
	ToGen = {}
	PRK_Gen_RoomStart( rooms.start[1], origin )
	PRK_Gen_RoomEnd( room, true )
	-- ToGen = {
		-- {
			-- AttachPoints = {
				-- {
					-- Pos = origin
				-- }
			-- }
		-- }
	-- }
	PrintTable( ToGen )
	PRK_Gen_Step( zone )
end

-- local room = nil
local plan
local index_try = 1
local orient_try = 1
local function next_attach()
	-- Ensure parents are removed
	for k, v in pairs( room.Ents ) do
		v:SetParent( nil )
	end

	-- Reset for next point
	room = nil
	orient_try = 1
	inde = 1
	CurrentRoomID = CurrentRoomID + 1

	-- Remove ToGen element if no more attachpoints to try
	if ( ToGen[1] ) then
		table.remove( ToGen[1].AttachPoints, 1 )
		if ( #ToGen[1].AttachPoints == 0 ) then
			table.remove( ToGen, 1 )
		end
	end
end
local function getrotatedfloor( v, anchor )
	local min, max = v:OBBMins(), v:OBBMaxs()
		-- Slightly smaller to avoid border crossover
		local bor = PRK_GEN_COLLISION_BORDER
		min = min * bor
		max = max * bor
		if ( v.Collide and v.Collide != true ) then -- Must be table
			min = min + Vector( 0, 0, v.Collide[1] )
			max = max + Vector( 0, 0, v.Collide[2] )
		end
		if ( math.abs( anchor:GetAngles().y ) == 90 ) then
			local temp = max - Vector() -- Take 0 to return value rather than reference
			max.x = temp.y
			max.y = temp.x
			local temp = min - Vector() -- Take 0 to return value rather than reference
			min.x = temp.y
			min.y = temp.x
		end
	return min, max
end
function PRK_Gen_Step( zone )
	if ( !ToGen or #ToGen == 0 or #ToGen[1].AttachPoints == 0 ) then
		PRK_Gen_End()
		return
	end

	local function next_step()
		if ( PRK_Gen_StepBetweenTime == 0 ) then
			PRK_Gen_Step( zone )
		else
			timer.Simple( PRK_Gen_StepBetweenTime, function() PRK_Gen_Step( zone ) end )
		end
	end

	if ( !room ) then
		local roomid = math.random( 1, #rooms )
		PRK_Gen_RoomStart( rooms[roomid], ToGen[1].AttachPoints[1].Pos )
	else
		local att = room.AttachPoints[index_try]
		-- print( "-0" )
		-- print( index_try )
		-- PrintTable( room.AttachPoints )

		-- Move anchor to correct position
		local anchor = HelperModels["Anchor"].Ent
		anchor:SetPos( room.Origin + att.Pos )
		anchor:SetAngles( HelperModels["Anchor"].Angle )

		-- Parent all to anchor helper
		for k, v in pairs( room.Ents ) do
			v:SetParent( anchor )
		end

		-- Rotate
		anchor:SetAngles( HelperModels["Anchor"].Angle + Angle( 0, 90 * ( orient_try - 1 ), 0 ) )

		-- Move anchor to origin attach point
		anchor:SetPos( room.Origin )

		-- If no collision then store this room
		local collide = false
		for _, v in pairs( room.Ents ) do
			if ( v.Collide ) then
				local pos = v:GetPos()
				local min, max = getrotatedfloor( v, anchor )
				for k, collision in pairs( ents.FindInBox( pos + min, pos + max ) ) do
					if ( collision.Collide and collision.PRK_Room != nil and collision.PRK_Room != CurrentRoomID ) then
						collide = true
						debugoverlay.Box( pos, min, max, PRK_Gen_StepBetweenTime, Color( 255, 0, 0, 100 ) )
						break
					end
				end
				debugoverlay.Box( pos, min, max, PRK_Gen_StepBetweenTime, Color( 255, 255, 0, 100 ) )
			end
			-- Break out early, only needs to collide once to fail
			if ( collide ) then
				break
			end
		end
		if ( !collide ) then
			PRK_Gen_RoomEnd( room )

			next_step()

			return
		end

		-- Otherwise undo rotation and parents
		anchor:SetPos( room.Origin + att.Pos )
		anchor:SetAngles( HelperModels["Anchor"].Angle )
		for k, v in pairs( room.Ents ) do
			v:SetParent( nil )
		end

		-- Setup next
		orient_try = orient_try + 1
		if ( orient_try > 4 ) then
			orient_try = 1
			index_try = index_try + 1
			if ( index_try > #room.AttachPoints ) then
				for p, ent in pairs( room.Ents ) do
					ent:Remove()
				end
				next_attach()
			end
		end
	end

	next_step()
end

function PRK_Gen_RoomStart( plan, origin )
	room = {}
		room.Plan = plan
		room.Origin = origin
	room.Ents = {}
	for k, mod in pairs( plan.Models ) do
		if ( !PRK_Gen_IgnoreEnts or !PRK_Gen_IgnoreEnts[mod.Type] ) then
			local class = "prop_physics"
				if ( mod.Type == PRK_GEN_TYPE_FLOOR ) then
					class = "prk_floor"
				elseif ( mod.Type == PRK_GEN_TYPE_WALL ) then
					class = "prk_wall"
				elseif ( mod.Type == PRK_GEN_TYPE_CEILING ) then
					class = "prk_ceiling"
				end
			local ent = PRK_CreateEnt(
				class,
				mod.Mod,
				room.Origin + mod.Pos,
				mod.Ang,
				true,
				true
			)
				ent.Size = mod.Size
				if ( ent.Size and type(ent.Size) == "table" ) then
					ent:SetPos( ent:GetPos() + Vector( ent.Size[1] / 2, -ent.Size[2] / 2, 0 ) )
				end
				if ( mod.Type != nil ) then
					ent:SetMaterial( PRK_GEN_TYPE_MAT[mod.Type] )
				end
				if ( #room.Ents != 0 ) then
					ent:SetParent( room.Ents[1] )
				end
				ent.Collide = mod.Collide or PRK_GEN_COLLIDE_ALL
				ent.PRK_Room = CurrentRoomID
			ent:Spawn()
			ent:SetZone( zone )
			table.insert( room.Ents, ent )
		end
	end
	room.AttachPoints = table.shallowcopy( plan.AttachPoints )

	index_try = 1
	orient_try = 1
end

function PRK_Gen_RoomEnd( room, force )
	table.insert( LastGen, room )

	local anchor = HelperModels["Anchor"].Ent
	local helper = HelperModels["Attach"].Ent
	local att = room.AttachPoints[index_try]

	local temp_orient = orient_try
	-- Add newest room
	local temp_room = LastGen[#LastGen]
	local attachpoints = {}
	for k, v in pairs( temp_room.AttachPoints ) do
		-- Chance to not use this attach point
		-- With less chance as the generation continues
		local use = true
		if ( !force ) then
			local donttarget = PRK_GEN_DONT
			local rnd = math.random( 1, donttarget ) * ( CurrentRoomID * PRK_GEN_DONT_SIZEMULT )
			if ( rnd >= donttarget ) then
				use = false
			end
		end

		if ( force ) then
			local point = {
				Pos = temp_room.Origin + v.Pos,
			}
			debugoverlay.Sphere( point.Pos, 10, PRK_Gen_StepBetweenTime, Color( 255, 0, 0, 255 ) )
			table.insert( attachpoints, point )
		else
			-- Undo parent
			helper:SetParent( nil )

			-- Undo move
			anchor:SetPos( temp_room.Origin + att.Pos )

			-- Undo rotation
			anchor:SetAngles( HelperModels["Anchor"].Angle )

			-- Set attach helper position
			helper:SetPos( temp_room.Origin + v.Pos )

			-- Parent back to anchor
			helper:SetParent( anchor )

			-- Rotate back
			anchor:SetAngles( HelperModels["Anchor"].Angle + Angle( 0, 90 * ( orient_try - 1 ), 0 ) )

			-- Move back
			anchor:SetPos( temp_room.Origin )

			-- Store or cap off attach point
			local point = {
				Pos = helper:GetPos(),
			}
				-- Calculate each end of the attach using this pos, the angle of rotation, and the size of the attach gap
				local size = math.max( math.abs( v.Min.x ), math.abs( v.Min.y ) )
				print( size )
				local dir = Vector( 1, 0, 0 )
				point.Min = point.Pos - dir * size
				point.Max = point.Pos + dir * size
			if ( use and k != index_try ) then
				table.insert( attachpoints, point )
			end
			PrintTable( point )
			local debugoff = Vector( 0, 0, 50 )
			debugoverlay.Sphere( debugoff + point.Pos, 10, 100, Color( 255, 0, 0, 255 ) )
			debugoverlay.Line( debugoff + point.Min, debugoff + point.Max, 100, Color( 255, 255, 255, 255 ), true )
		end
	end

	-- Spawn objects as entities
	if ( !PRK_Gen_IgnoreEnts or !PRK_Gen_IgnoreEnts[4] ) then
		for k, v in pairs( temp_room.Plan.Objects ) do
			if ( v.Editor_Ent and SpawnEditorEnt[v.Editor_Ent] ) then
				-- Undo parent
				helper:SetParent( nil )

				if ( force ) then
					helper:SetPos( temp_room.Origin + v.Pos )
					helper:SetAngles( v.Angles )
				else
					-- Undo move
					anchor:SetPos( temp_room.Origin + att.Pos )

					-- Undo rotation
					anchor:SetAngles( HelperModels["Anchor"].Angle )

					-- Set attach helper position
					helper:SetPos( temp_room.Origin + v.Pos )
					helper:SetAngles( v.Angles )

					-- Parent back to anchor
					helper:SetParent( anchor )

					-- Rotate back
					anchor:SetAngles( HelperModels["Anchor"].Angle + Angle( 0, 90 * ( orient_try - 1 ), 0 ) )

					-- Move back
					anchor:SetPos( temp_room.Origin )
				end

				-- Spawn entity
				local ent = SpawnEditorEnt[v.Editor_Ent]( helper:GetPos(), helper:GetAngles(), v.Scale, v.Model )
			end
		end
	end

	-- Add navmeshes
	local navs = {}
	for _, v in pairs( room.Ents ) do
		if ( v.Collide ) then
			local pos = v:GetPos()
			local border = 0.5
			local min, max = getrotatedfloor( v, anchor )
				min = min * border
				max = max * border
			local nav = navmesh.CreateNavArea( pos + min, pos + max )
			table.insert( navs, nav )
		end
	end
	-- Connect navmeshes
	-- This crashes the game (?????)
	--local maxdist = 200
	--for _, nav1 in pairs( navs ) do
	--	for m, nav2 in pairs( navs ) do
	--		-- Check each nav against every other nav (other than self)
	--		if ( nav1 != nav2 ) then
	--			-- If it's close and has no raycast hit between then it can link
	--			local function getmid( nav )
	--				return (
	--					nav:GetCorner( 0 ) +
	--					nav:GetCorner( 1 ) +
	--					nav:GetCorner( 2 ) +
	--					nav:GetCorner( 3 )
	--				) / 4
	--			end
	--			local dist = getmid( nav1 ):Distance( getmid( nav2 ) )
	--			-- print( dist )
	--			if ( dist <= maxdist ) then
	--				-- print( nav1 )
	--				-- print( nav2 )
	--				-- timer.Simple( 1, function()
	--					-- nav1:ConnectTo( nav2 )
	--				-- end )
	--				-- nav2:ConnectTo( nav1 )
	--			end
	--		end
	--	end
	--end

	-- Must be after attach point etc
	next_attach()

	table.insert( ToGen, { AttachPoints = attachpoints } )
end

function PRK_Gen_End()
	-- Remove each helper model entity
	for k, v in pairs( HelperModels ) do
		v.Ent:Remove()
		v.Ent = nil
	end
end

function PRK_Gen_RotateAround( room, attach, angle )
	local ent = room.Ents[1]
		if ( !ent.OriginalPos ) then
			ent.OriginalPos = ent:GetPos()
		end
	local attpos = attach.Pos

	local mat_inverse = Matrix()
		mat_inverse:SetTranslation( attpos )

	local mat_rot = Matrix()
		mat_rot:SetAngles( ent:GetAngles() + Angle( 0, angle, 0 ) )

	local mat_trans = Matrix()
		mat_trans:SetTranslation( -attpos )

	-- Move to origin, rotate, move from origin
	local mat_final = ( mat_inverse * mat_rot ) * mat_trans
	local pos = mat_final:GetTranslation()
	local ang = mat_final:GetAngles()
	ent:SetPos( ent.OriginalPos + pos )
	ent:SetAngles( ang )
end

function PRK_Gen_RotatePointAround( point, pointangle, attach, angle )
	local attpos = attach.Pos

	local mat_inverse = Matrix()
		mat_inverse:SetTranslation( attpos )

	local mat_rot = Matrix()
		mat_rot:SetAngles( pointangle + Angle( 0, angle, 0 ) )

	local mat_trans = Matrix()
		mat_trans:SetTranslation( -attpos )

	-- Move to origin, rotate, move from origin
	local mat_final = ( mat_inverse * mat_rot ) * mat_trans
	local pos = mat_final:GetTranslation()
	local ang = mat_final:GetAngles()
	return pos, ang
end

function PRK_Gen_LoadRooms()
	local rooms = {}
		-- Find all room data files
		local index = nil
		local function handlefiles( files )
			if ( index and !rooms[index] ) then
				rooms[index] = {}
			end
			for k, filename in pairs( files ) do
				local path = filename
					if ( index ) then
						path = index .. "/" .. filename
					end
				local room = file.Read( PRK_DataPath .. path )
					room = PRK_Gen_LoadRooms_Parse( room )
				if ( index ) then
					table.insert( rooms[index], room )
				else
					table.insert( rooms, room )
				end
			end
		end
		local files, directories = file.Find( PRK_DataPath .. "*", "DATA" )
		handlefiles( files )
		for k, dir in pairs( directories ) do
			index = dir
			local files, directories = file.Find( PRK_DataPath .. index .. "/*", "DATA" )
			handlefiles( files )
		end
	return rooms
end

function PRK_Gen_LoadRooms_Parse( room )
	-- Convert from json back to table format
	room = util.JSONToTable( room )

	-- Parse the room creation instructions into the correct level gen instructions
	room.AttachPoints = {}
	room.Models = {}

	-- Floors
	for _, part in pairs( room.Parts ) do
		if ( part.isattach ) then
			-- table.insert( room.AttachPoints, { Pos = part.position } )
		else
			table.insert( room.Models, {
				Pos = part.position,
				Ang = Angle( 0, 0, 0 ),
				Size = { part.width, part.breadth },
				Mod = "models/hunter/plates/plate1x1.mdl",
				Type = PRK_GEN_TYPE_FLOOR,
				Collide = true,
			} )
		end
	end

	-- Walls
	PRK_Gen_LoadRooms_Walls( room )

	-- Ceilings
	for _, part in pairs( room.Parts ) do
		if ( !part.isattach ) then
			table.insert( room.Models, {
				Pos = part.position + Vector( 0, 0, 8 * PRK_Editor_Square_Size ),
				Ang = Angle( 0, 0, 0 ),
				Size = { part.width, part.breadth },
				Mod = "models/hunter/plates/plate1x1.mdl",
				Type = PRK_GEN_TYPE_CEILING,
				Collide = true,
			} )
		end
	end

	-- Ents
	room.Objects = {}
	for _, model in pairs( room.ModelExportInstructions ) do
		table.insert( room.Objects, model )
	end

	-- Debug output
	-- PrintTable( room )

	return room
end

function PRK_Gen_LoadRooms_Walls( room )
	-- For each floor part
	for _, part in pairs( room.Parts ) do
		if ( !part.isattach ) then
			-- For each edge
			local scale = PRK_Editor_Square_Size * PRK_Editor_Grid_Scale
			local sides = {
				-- Left
				{
					x = 0,
					y = 0,
					w = 0,
					b = 1,
				},
				-- Right
				{
					x = 1,
					y = 0,
					w = 0,
					b = 1,
				},
				-- Top
				{
					x = 0,
					y = 0,
					w = 1,
					b = 0,
				},
				-- Right
				{
					x = 0,
					y = 1,
					w = 1,
					b = 0,
				},
			}
			local function getbounds( part, side )
				local x = math.Round( ( part.position.x + part.width * side.x ) / scale )
				local y = math.Round( ( -part.position.y + part.breadth * side.y ) / scale )
				local w = math.Round( part.width * side.w / scale )
				local b = math.Round( part.breadth * side.b / scale )
				return x, y, w, b
			end
			for k, side in pairs( sides ) do
				local x, y, w, b = getbounds( part, side )
				local base = Entity(1):GetPos() + Entity(1):GetEyeTrace().Normal * 20
				local pos1 = base + Vector( x, -y, 0 )
				local pos2 = base + Vector( x + w, -y - b, 0 )
				-- debugoverlay.Line( pos1, pos2, 110, Color( 255, 255, 255, 255 ), true )
				local wallsegs = {}
				local attachsegs = {}
				-- Subdivide into grid segments
				local length = math.max( w, b )
				for i = 0, length - 1 do
					-- Check each segment for if it needs a wall
					local x = side.w == 1 and x + i or x
					local y = side.b == 1 and y + i or y
					local w = side.w == 1 and 1 or w
					local b = side.b == 1 and 1 or b
					-- Against every edge of every other part
					local hitfloor = false
						local mid = Vector( x + w / 2, y + b / 2, 0 )
						for _, otherpart in pairs( room.Parts ) do
							if ( otherpart != part ) then
								for _, otherside in pairs( sides ) do
									local x, y, w, b = getbounds( otherpart, otherside )
									local start = Vector( x, y, 0 )
									local finish = Vector( x + w, y + b, 0 )
									if ( intersect_point_line( mid, start, finish ) ) then
										if ( otherpart.isattach ) then
											table.insert( attachsegs, i )
										end
										hitfloor = true
										break
									end
								end
								if ( hitfloor ) then
									break
								end
							end
						end
					if ( !hitfloor ) then
						table.insert( wallsegs, i )
					end

					-- local pos1 = base + Vector( x, -y, -0.1 )
					-- local pos2 = base + Vector( x + w, -y - b, -0.1 )
					-- local col = Color( 255, 255, 255, 255 )
						-- if ( !hitfloor ) then col = Color( 255, 0, 255, 255 ) end
					-- debugoverlay.Line( pos1, pos2, 110, col, true )
				end
				-- Combine any continuous segements into one wall entity
				local function combinecontinuous( segs )
					local combinedsegs = {}
						local chain = -1
						local lastval = -1
						for q, seg in pairs( segs ) do
							-- Last value ends chain automatically
							if ( q == #segs ) then
								lastval = seg
							end
							-- Begin chain if none currently
							if ( chain == -1 ) then
								chain = seg
							end
							-- End chain if there is a gap between some values
							if ( lastval != -1 and lastval != seg - 1 ) then
								table.insert( combinedsegs, { chain, lastval - chain + 1 } )
								chain = seg
							end
							lastval = seg
						end
					return combinedsegs
				end
				local combinedwallsegs = combinecontinuous( wallsegs )
				-- Add walls
				for q, seg in pairs( combinedwallsegs ) do
					local x = side.w == 1 and x + seg[1] or x
					local y = side.b == 1 and y + seg[1] or y
					local pos = Vector( x, -y, 8 ) * scale
					local ang = Angle( -90, 0, 0 )
						if ( side.w == 1 ) then ang = Angle( -90, 90, 0 ) end
					table.insert( room.Models, {
						Pos = pos,
						Ang = ang,
						Size = { seg[2] * scale * side.w, seg[2] * scale * side.b },
						Mod = "models/hunter/plates/plate1x1.mdl",
						Type = PRK_GEN_TYPE_WALL,
					} )
				end
				-- Add attach points
				local combinedattachsegs = combinecontinuous( attachsegs )
				for q, seg in pairs( combinedattachsegs ) do
					local x = side.w == 1 and x + seg[1] or x
					local y = side.b == 1 and y + seg[1] or y
					local min = Vector( x, -y, 0 )
					local max = Vector( seg[2] * side.w, -seg[2] * side.b, 0 )
					local pos = min + max / 2
						pos = pos * scale
					table.insert( room.AttachPoints, { Pos = pos, Min = min, Max = max } )
				end

				-- Debug output
				for q, seg in pairs( combinedwallsegs ) do
					local x = side.w == 1 and x + seg[1] or x
					local y = side.b == 1 and y + seg[1] or y
					local w = side.w == 1 and seg[2] or w
					local b = side.b == 1 and seg[2] or b
					local pos1 = base + Vector( x, -y, 0 )
					local pos2 = base + Vector( x + w, -y - b, 0 )
					local col = Color( 255, 0, 255, 255 )
					debugoverlay.Line( pos1, pos2, 110, col, true )
				end
			end
		end
	end
end

function PRK_Gen_Remove()
	for k, v in pairs( LastGen ) do
		for _, ent in pairs( v.Ents ) do
			if ( ent and ent:IsValid() ) then
				ent:Remove()
			end
		end
	end
	LastGen = {}
end
