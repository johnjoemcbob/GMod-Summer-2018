--
-- Prickly Summer 2018
-- 03/06/18
--
-- Level Generation
--

local size = 47.45
local hsize = size / 2

local DefaultRooms = {
	-- Default room
	{
		Models = {
			{
				Pos = Vector( 0, 0, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
			},
			{
				Pos = Vector( size * 8, 0, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
			},
			{
				Pos = Vector( -size * 8, 0, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
			},
			{
				Pos = Vector( 0, size * 8, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
			},
			{
				Pos = Vector( 0, -size * 8, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
			},
			{
				Pos = Vector( size * 8, size * 8, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
			},
			{
				Pos = Vector( -size * 8, -size * 8, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
			},
			{
				Pos = Vector( -size * 8, size * 8, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
			},
			{
				Pos = Vector( size * 8, -size * 8, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
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
			{
				Pos = Vector( 0, 0, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
			},
			{
				Pos = Vector( size * 8, 0, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
			},
			{
				Pos = Vector( 0, size * 8, 0 ),
				Ang = Angle( 0, 0, 0 ),
				Mod = "models/hunter/plates/plate8x8.mdl",
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
			{
				Pos = Vector( 0, 0, 0 ),
				Ang = Angle( 0, 0, 0 ),
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

local LastGen = {}
local CurrentRoomID = 0

concommand.Add( "prk_gen", function( ply, cmd, args )
	PRK_Gen_Remove()
	PRK_Gen( ply:GetPos() - Vector( 0, 0, 100 ) )
end )

concommand.Add( "prk_test", function( ply, cmd, args )
	for k, room in pairs( LastGen ) do
		PRK_Gen_RotateAround( room, 1, 45 )
	end
end )

concommand.Add( "prk_test2", function( ply, cmd, args )
	for k, room in pairs( LastGen ) do
		PRK_Gen_RotateAround( room, 2, 45 )
	end
end )

function PRK_Gen( origin )
	LastGen = {}
	CurrentRoomID = 0

	-- Generate first room
	PRK_Gen_Room( origin )

	-- Loop through all connections and generate more rooms for them
	-- Maybe based on a grid array of open spaces, fill in by size of room?
	-- Could also just spawn the props and check for collision but would be slow i guess
	local tries = 100
	for k, room in pairs( LastGen ) do
		for _, attach in pairs( room.AttachPoints ) do
			if ( tries <= 0 ) then
				return
			end
			if ( !attach.Attached ) then
				-- Chance to lead somewhere
				if ( math.random( 1, 10 ) != 1 ) then
					debugoverlay.Sphere(
						room.Origin + attach.Pos,
						10,
						20,
						Color( 100, 100, 255, 255 ),
						true
					)
					PRK_Gen_Room( room.Origin + attach.Pos, attach )
					debugoverlay.Line( room.Origin, room.Origin + attach.Pos, 20, Color( 100, 0, 100, 200 ), true )
					PrintTable( room )
					print( "more room" )
				end
				LastGen[k].AttachPoints[_].Attached = true
				tries = tries - 1
			end
		end
	end
end

function PRK_Gen_Room( origin, attachto )
	local room = {}
		room.Origin = origin

		-- Choose a random room
		local rnd = DefaultRooms[math.random( 1, #DefaultRooms )]

		-- Check room attach
		local att
		if ( attachto ) then
			-- local att = rnd.AttachPoints[math.random( 1, #rnd.AttachPoints )]

			-- Instead of random
			-- Take the opposite of the attachto direction and try to find a match
			local opposite = VectorNegate( attachto.Dir ) -- attachto.Dir --
				for k, v in pairs( rnd.AttachPoints ) do
					if ( opposite == v.Dir ) then
						att = v
						break
					end
				end
			if ( !att ) then
				return
			end
		end

		-- Add the room visuals/physics
		room.Ents = {}
		for k, mod in pairs( rnd.Models ) do
			local ent = PRK_CreateProp(
				mod.Mod,
				room.Origin + mod.Pos,
				mod.Ang
			)
			if ( #room.Ents != 0 ) then
				ent:SetParent( room.Ents[1] )
			end
			ent.PRK_Room = CurrentRoomID
			table.insert( room.Ents, ent )
		end

		-- Move room to attach
		if ( attachto ) then
			-- First move position
			room.Ents[1]:SetPos( room.Ents[1]:GetPos() - att.Pos )
			debugoverlay.Line( room.Origin - att.Pos, room.Origin, 20, Color( 255, 0, 255, 200 ), true )
			room.Origin = room.Origin - att.Pos

			-- Then figure out how to match rotation
		end

		-- Check space at spot
		for _, v in pairs( rnd.GenerateShape ) do
			local min, max = v[1], v[2]
				-- Slightly smaller to avoid border crossover
				local bor = 95 / 100
				min = min * bor
				max = max * bor
			for k, collision in pairs( ents.FindInBox( room.Origin + min, room.Origin + max ) ) do
				if ( collision.PRK_Room != nil and collision.PRK_Room != CurrentRoomID ) then
					-- Remove this room
					print( collision )
					for p, ent in pairs( room.Ents ) do
						ent:Remove()
					end
					return
				end
			end
			debugoverlay.Box( room.Origin, min, max, 10, Color( 255, 255, 0, 100 ) )
		end

		-- Visualise attach points
		for k, v in pairs( rnd.AttachPoints ) do
			PRK_BasicDebugSphere( room.Origin + v.Pos )
		end
		-- Store attach for next genroom
		room.AttachPoints = table.shallowcopy( rnd.AttachPoints )
		if ( attachto ) then
			-- Remove the currently attached point
			for k, v in pairs( room.AttachPoints ) do
				if ( v.Pos == att.Pos ) then
					room.AttachPoints[k].Attached = true
				end
			end
		end

		-- Spawn points
		-- todo

		-- Remove parents after reorienting
		for k, ent in pairs( room.Ents ) do
			ent:SetParent( nil )
		end

		-- Last: Increment room ID
		CurrentRoomID = CurrentRoomID + 1
	table.insert( LastGen, room )
end

function PRK_Gen_RotateAround( room, attach, angle )
	local ent = room.Ents[1]
		if ( !ent.OriginalPos ) then
			ent.OriginalPos = ent:GetPos()
		end
	local attpos = room.AttachPoints[attach].Pos

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
