AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

PRK_Floors = {}
PRK_Floor_Plants = {}

util.AddNetworkString( "PRK_Floor_Grass" )
util.AddNetworkString( "PRK_Floor_Plant" )

function PRK_Send_Floor_Grass( ply, zone, pos, min, max )
	if ( !zone ) then return end

	net.Start( "PRK_Floor_Grass" )
		net.WriteFloat( zone )
		net.WriteVector( pos )
		net.WriteVector( min )
		net.WriteVector( max )
	net.Send( ply )
end

function PRK_Send_Floor_Plant( ply, zone )
	if ( !zone ) then return end

	local count = #PRK_Floor_Plants[zone]
	net.Start( "PRK_Floor_Plant" )
		net.WriteFloat( zone )
		net.WriteFloat( count )
		for k, plant in pairs( PRK_Floor_Plants[zone] ) do
			net.WriteFloat( plant[1] )
			net.WriteVector( plant[2] )
			net.WriteAngle( plant[3] )
			net.WriteFloat( plant[4] )
			net.WriteFloat( plant[5] )
		end
	net.Send( ply )
end

function PRK_Floor_MoveToZone( ply, zone )
	if ( PRK_Floors[zone] ) then
		for k, floor in pairs( PRK_Floors[zone] ) do
			PRK_Send_Floor_Grass( ply, zone, floor[1], floor[2], floor[3] )
		end
		PRK_Send_Floor_Plant( ply, zone )
	end
end

function ENT:Initialize()
	self:SetModel( "models/hunter/plates/plate1x1.mdl" )
	local min = Vector( -self.Size[1] / 2, -self.Size[2] / 2, -2 )
	local max = -min

	self:PhysicsInitConvex( {
		Vector( min.x, min.y, min.z ),
		Vector( min.x, min.y, max.z ),
		Vector( min.x, max.y, min.z ),
		Vector( min.x, max.y, max.z ),
		Vector( max.x, min.y, min.z ),
		Vector( max.x, min.y, max.z ),
		Vector( max.x, max.y, min.z ),
		Vector( max.x, max.y, max.z )
	} )

	-- Set up solidity and movetype
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	-- Enable custom collisions on the entity
	self:EnableCustomCollisions( true )

	-- Freeze initial body
	local phys = self:GetPhysicsObject()
	if ( phys and phys:IsValid() ) then
		phys:Wake()
		phys:EnableMotion( false )
	end

	-- Lock in the floor and remove this entity
	timer.Simple( PRK_Floor_Delete_Time * 1.1, function()
		if ( self and self:IsValid() ) then
			-- Store position for visuals
			local min, max = self:GetCollisionBounds()
			if ( self.Zone ) then
				if ( !PRK_Floors[self.Zone] ) then
					PRK_Floors[self.Zone] = {}
				end
				table.insert( PRK_Floors[self.Zone], {
					self:GetPos(),
					min,
					max,
				} )
			end
			self:GeneratePlants()

			-- Remove the entity for performance
			self:Remove()
		end
	end )
end

function ENT:GeneratePlants()
	-- Plant models
	local between = 1
	local function createplants()
		if ( self.Zone != nil ) then
			if ( !PRK_Floor_Plants ) then
				PRK_Floor_Plants = {}
			end
			if ( !PRK_Floor_Plants[self.Zone] ) then
				PRK_Floor_Plants[self.Zone] = {}
			end

			-- local min = self:OBBMins()
			-- local max = self:OBBMaxs()
			local min, max = self:GetCollisionBounds()
			local sca = Vector( max.x / PRK_Plate_Size * 2, max.y / PRK_Plate_Size * 2, 1 )
			local precision = 10
			local amount = math.floor( math.random( PRK_Grass_Mesh_CountRange[1] * precision, PRK_Grass_Mesh_CountRange[2] * precision ) / precision * ( sca.x + sca.y ) )
			for i = 1, amount do
				local ind = math.random( 1, #PRK_Floor_Models )
				local rnd = PRK_Floor_Models[ind]
				local pos = self:GetPos() + Vector( math.random( min.x, max.x ), math.random( min.y, max.y ), math.random( min.z, max.z ) ) + rnd[2]
				local ang = rnd[3] + Angle( math.random( -10, 10 ), math.random( 0, 360 ), math.random( -10, 10 ) )
				local sca = math.random( rnd[5][1] * 100, rnd[5][2] * 100 ) / 100
				local col = math.random( 1, #PRK_Floor_Colours )

				table.insert( PRK_Floor_Plants[self.Zone], {
					ind,
					pos,
					ang,
					sca,
					col
				} )
			end
		else
			timer.Simple( between, function() createplants() end )
		end
	end
	createplants()
end
