--
-- Prickly Summer 2018
-- 03/06/18
--
-- Level Generation
--

local DEBUG = true


local size = 47.45
local hsize = size / 2

local DefaultRooms = {
	-- Default room
	{
		Models = {
			-- Floor
			{
				Pos = Vector( 0, 0, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
				Collide = true,
			},
			{
				Pos = Vector( size * 8, 0, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
				Collide = true,
			},
			{
				Pos = Vector( -size * 8, 0, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
				Collide = true,
			},
			{
				Pos = Vector( 0, size * 8, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
				Collide = true,
			},
			{
				Pos = Vector( 0, -size * 8, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
				Collide = true,
			},
			{
				Pos = Vector( size * 8, size * 8, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
				Collide = true,
			},
			{
				Pos = Vector( -size * 8, -size * 8, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
				Collide = true,
			},
			{
				Pos = Vector( -size * 8, size * 8, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
				Collide = true,
			},
			{
				Pos = Vector( size * 8, -size * 8, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
				Collide = true,
			},

			-- Walls
			{
				Pos = Vector( size * 8 + hsize * 8, -size * 8, 0 ),
				Ang = Angle( 90, 0, 0 ),
				Mod = "models/hunter/plates/plate3x8.mdl",
			},
			{
				Pos = Vector( size * 8 + hsize * 8, size * 8, 0 ),
				Ang = Angle( 90, 0, 0 ),
				Mod = "models/hunter/plates/plate3x8.mdl",
			},
			{
				Pos = Vector( -size * 8 - hsize * 8, -size * 8, 0 ),
				Ang = Angle( 90, 0, 0 ),
				Mod = "models/hunter/plates/plate3x8.mdl",
			},
			{
				Pos = Vector( -size * 8 - hsize * 8, size * 8, 0 ),
				Ang = Angle( 90, 0, 0 ),
				Mod = "models/hunter/plates/plate3x8.mdl",
			},
			{
				Pos = Vector( -size * 8, size * 8 + hsize * 8, 0 ),
				Ang = Angle( 90, 90, 0 ),
				Mod = "models/hunter/plates/plate3x8.mdl",
			},
			{
				Pos = Vector( size * 8, size * 8 + hsize * 8, 0 ),
				Ang = Angle( 90, 90, 0 ),
				Mod = "models/hunter/plates/plate3x8.mdl",
			},
			{
				Pos = Vector( -size * 8, -size * 8 - hsize * 8, 0 ),
				Ang = Angle( 90, 90, 0 ),
				Mod = "models/hunter/plates/plate3x8.mdl",
			},
			{
				Pos = Vector( size * 8, -size * 8 - hsize * 8, 0 ),
				Ang = Angle( 90, 90, 0 ),
				Mod = "models/hunter/plates/plate3x8.mdl",
			},

			-- Door placehold
			{
				Pos = Vector( size * 8 + hsize * 8, 0, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/props/de_inferno/archwaysupport.mdl",
			},
			{
				Pos = Vector( -size * 8 + - hsize * 8, 0, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/props/de_inferno/archwaysupport.mdl",
			},
			{
				Pos = Vector( 0, size * 8 + hsize * 8, 0 ),
				Ang = Angle( 0, 90, 0 ),
				Mod = "models/props/de_inferno/archwaysupport.mdl",
			},
			{
				Pos = Vector( 0, -size * 8 - hsize * 8, 0 ),
				Ang = Angle( 0, 90, 0 ),
				Mod = "models/props/de_inferno/archwaysupport.mdl",
			},
		},
		AttachPoints = {
			{
				Pos = Vector( size * 8 + hsize * 8, 0, 0 ),
				Dir = Vector( 1, 0, 0 ),
			},
			{
				Pos = Vector( -size * 8 - hsize * 8, 0, 0 ),
				Dir = Vector( -1, 0, 0 ),
			},
			{
				Pos = Vector( 0, size * 8 + hsize * 8, 0 ),
				Dir = Vector( 0, 1, 0 ),
			},
			{
				Pos = Vector( 0, -size * 8 - hsize * 8, 0 ),
				Dir = Vector( 0, -1, 0 ),
			},
		},
		SpawnPoints = {
			-- Position, angle, type
		},
		-- The box min/maxes to check before spawning this room in a position
		GenerateShape = {
			{
				Vector( -size * 8 - hsize * 8, -size * 8 - hsize * 8, 0 ),
				Vector( size * 8 + hsize * 8, size * 8 + hsize * 8, 5 )
			},
		},
	},
	-- L room
	{
		Models = {
			-- Floor
			{
				Pos = Vector( 0, 0, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
				Collide = true,
			},
			{
				Pos = Vector( size * 8, 0, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
				Collide = true,
			},
			{
				Pos = Vector( 0, size * 8, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
				Collide = true,
			},

			-- Walls
			{
				Pos = Vector( -hsize * 8, 0, 0 ),
				Ang = Angle( 90, 0, 0 ),
				Mod = "models/hunter/plates/plate3x8.mdl",
			},
			{
				Pos = Vector( -hsize * 8, size * 8, 0 ),
				Ang = Angle( 90, 0, 0 ),
				Mod = "models/hunter/plates/plate3x8.mdl",
			},
			{
				Pos = Vector( 0, -hsize * 8, 0 ),
				Ang = Angle( 90, 90, 0 ),
				Mod = "models/hunter/plates/plate3x8.mdl",
			},
			{
				Pos = Vector( size * 8, -hsize * 8, 0 ),
				Ang = Angle( 90, 90, 0 ),
				Mod = "models/hunter/plates/plate3x8.mdl",
			},
			{
				Pos = Vector( hsize * 8, size * 8, 0 ),
				Ang = Angle( 90, 0, 0 ),
				Mod = "models/hunter/plates/plate3x8.mdl",
			},
			{
				Pos = Vector( size * 8, hsize * 8, 0 ),
				Ang = Angle( 90, 90, 0 ),
				Mod = "models/hunter/plates/plate3x8.mdl",
			},

			-- Door placehold
			{
				Pos = Vector( size * 8 + hsize * 8, 0, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/props/de_inferno/archwaysupport.mdl",
			},
			{
				Pos = Vector( 0, size * 8 + hsize * 8, 0 ),
				Ang = Angle( 0, 90, 0 ),
				Mod = "models/props/de_inferno/archwaysupport.mdl",
			},
		},
		AttachPoints = {
			{
				Pos = Vector( size * 8 + hsize * 8, 0, 0 ),
				Dir = Vector( 1, 0, 0 ),
			},
			{
				Pos = Vector( 0, size * 8 + hsize * 8, 0 ),
				Dir = Vector( 0, 1, 0 ),
			},
		},
		SpawnPoints = {
			-- Position, angle, type
		},
		-- The box min/maxes to check before spawning this room in a position
		GenerateShape = {
			{
				Vector( -size * 8 - hsize * 8, -size * 8 - hsize * 8, 0 ),
				Vector( size * 8 + hsize * 8, size * 8 + hsize * 8, 5 )
			},
		},
	},
	-- Corridor
	{
		Models = {
			-- Floor
			{
				Pos = Vector( 0, 0, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate3x8.mdl",
				Collide = true,
			},

			-- Wall
			{
				Pos = Vector( hsize * 3, 0, 0 ),
				Ang = Angle( 90, 0, 0 ),
				Mod = "models/hunter/plates/plate3x8.mdl",
			},
			{
				Pos = Vector( -hsize * 3, 0, 0 ),
				Ang = Angle( 90, 0, 0 ),
				Mod = "models/hunter/plates/plate3x8.mdl",
			},

			-- Door placehold
			{
				Pos = Vector( 0, hsize * 8, 0 ),
				Ang = Angle( 0, 90, 0 ),
				Mod = "models/props/de_inferno/archwaysupport.mdl",
			},
			{
				Pos = Vector( 0, -hsize * 8, 0 ),
				Ang = Angle( 0, 90, 0 ),
				Mod = "models/props/de_inferno/archwaysupport.mdl",
			},
		},
		AttachPoints = {
			{
				Pos = Vector( 0, hsize * 8, 0 ),
				Dir = Vector( 0, 1, 0 ),
			},
			{
				Pos = Vector( 0, -hsize * 8, 0 ),
				Dir = Vector( 0, -1, 0 ),
			},
		},
		SpawnPoints = {
			-- Position, angle, type
		},
		-- The box min/maxes to check before spawning this room in a position
		GenerateShape = {
			{
				Vector( -hsize * 3, -hsize * 8, 0 ),
				Vector( hsize * 3, hsize * 8, 5 )
			},
		},
	},
}

local HelperModels = {
	Anchor = {
		Model = "models/props_c17/pulleyhook01.mdl",
		Angle = Angle( 180, 0, 0 ),
	},
	Min = {
		Model = "models/mechanics/solid_steel/l-beam__16.mdl",
		Angle = Angle( 0, 0, 0 ),
	},
	Max = {
		Model = "models/hunter/tubes/tube2x2x+.mdl",
		Angle = Angle( 0, 0, 0 ),
	},
	Attach = {
		Model = "models/props_junk/PushCart01a.mdl",
		Angle = Angle( 0, 0, 0 ),
	},
}

local LastGen = {} -- Table of all rooms last generated
local ToGen = {} -- Table of rooms still to try attach points for
local CurrentRoomID = 0 -- Indices for rooms

concommand.Add( "prk_gen", function( ply, cmd, args )
	PRK_Gen_Remove()
	PRK_Gen( ply:GetPos() - Vector( 0, 0, 100 ) )
end )

concommand.Add( "prk_test", function( ply, cmd, args )
	PRK_Gen_Step( ply:GetPos() - Vector( 0, 0, 100 ) )
	-- for k, room in pairs( LastGen ) do
		-- PRK_Gen_RotateAround( room, 1, 45 )
	-- end
end )

local room
concommand.Add( "prk_test2", function( ply, cmd, args )
	-- for k, room in pairs( LastGen ) do
		if ( room.AttachPoints ) then
			PRK_Gen_RotateAround( room, room.AttachPoints[2], 90 )
		end
	-- end
end )

function PRK_Gen( origin )
	LastGen = {}
	CurrentRoomID = 0

	-- Create each helper model entity
	for k, v in pairs( HelperModels ) do
		local ent = PRK_CreateProp( v.Model, origin, v.Angle )
		v.Ent = ent
	end

--	-- Generate first room
--	PRK_Gen_Room( origin )
--
--	-- Loop through all connections and generate more rooms for them
--	-- Maybe based on a grid array of open spaces, fill in by size of room?
--	-- Could also just spawn the props and check for collision but would be slow i guess
--	local tries = 2
--	for k, room in pairs( LastGen ) do
--		for _, attach in pairs( room.AttachPoints ) do
--			if ( tries <= 0 ) then
--				return
--			end
--			if ( !attach.Attached ) then
--				-- Chance to lead somewhere
--				if ( math.random( 1, 10 ) != 1 ) then
--					PRK_Gen_Room( room.Origin + attach.Pos, attach )
--				end
--				LastGen[k].AttachPoints[_].Attached = true
--				tries = tries - 1
--			end
--		end
--	end
	ToGen = {
		{
			AttachPoints = {
				{
					Pos = origin
				}
			}
		}
	}
	PRK_Gen_Step()
end

-- local room = nil
local plan
local index_try = 1
local orient_try = 1
function PRK_Gen_Step()
	print( "step" )
	if ( !ToGen or #ToGen == 0 ) then return end

	local origin = ToGen[1].AttachPoints[1].Pos

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
		table.remove( ToGen[1].AttachPoints, 1 )
		if ( #ToGen[1].AttachPoints == 0 ) then
			table.remove( ToGen, 1 )
		end
	end
	local function next_step()
		timer.Simple( 1, function() PRK_Gen_Step() end )
	end

	if ( !room ) then
		print( "Create room!" )
		-- plan = DefaultRooms[2]
		plan = DefaultRooms[math.random( 1, #DefaultRooms )]

		room = {}
			room.Origin = origin
		room.Ents = {}
		for k, mod in pairs( plan.Models ) do
			local ent = PRK_CreateProp(
				mod.Mod,
				room.Origin + mod.Pos,
				mod.Ang
			)
			if ( #room.Ents != 0 ) then
				ent:SetParent( room.Ents[1] )
			end
			ent.Collide = mod.Collide
			ent.PRK_Room = CurrentRoomID
			table.insert( room.Ents, ent )
		end
		room.AttachPoints = table.shallowcopy( plan.AttachPoints )

		index_try = 1
		orient_try = 1
	else
		local att = room.AttachPoints[index_try]

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
				local min, max = v:OBBMins(), v:OBBMaxs()
					-- Slightly smaller to avoid border crossover
					local bor = 95 / 100
					min = min * bor
					max = max * bor
				for k, collision in pairs( ents.FindInBox( pos + min, pos + max ) ) do
					if ( collision.Collide and collision.PRK_Room != nil and collision.PRK_Room != CurrentRoomID ) then
						collide = true
						debugoverlay.Box( pos, min, max, 2, Color( 255, 0, 0, 100 ) )
					end
				end
				debugoverlay.Box( pos, min, max, 2, Color( 255, 255, 0, 100 ) )
			end
		end
		if ( !collide ) then
			table.insert( LastGen, room )

			local temp_orient = orient_try
			-- Add newest room
			local temp_room = LastGen[#LastGen]
			local attachpoints = {}
			for k, v in pairs( temp_room.AttachPoints ) do
				if ( k != index_try ) then
					local helper = HelperModels["Attach"].Ent
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

					-- Store pos
					local point = {
						Pos = helper:GetPos()
					}
					table.insert( attachpoints, point )
				end
			end

			-- Must be after attach point etc
			next_attach()

			table.insert( ToGen, { AttachPoints = attachpoints } )
			print( "not collide" )
			PrintTable( ToGen )

			next_step()

			return
		end

		-- Otherwise undo rotation and parents
		anchor:SetPos( room.Origin + att.Pos )
		anchor:SetAngles( HelperModels["Anchor"].Angle )
		for k, v in pairs( room.Ents ) do
			v:SetParent( nil )
		end

		-- setup next
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
