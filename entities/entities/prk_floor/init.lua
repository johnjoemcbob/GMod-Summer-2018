AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

PRK_Floors = {}
PRK_Floor_Plants = {}
PRK_Floor_Grid = {}

util.AddNetworkString( "PRK_Floor_Grass_Clear" )
util.AddNetworkString( "PRK_Floor_Grass" )
util.AddNetworkString( "PRK_Floor_Plant" )
util.AddNetworkString( "PRK_Floor_Grid" )

function PRK_Send_Floor_Grass_Clear( ply )
	net.Start( "PRK_Floor_Grass_Clear" )
	net.Send( ply )
end

function PRK_Send_Floor_Grass( ply, zone, pos, min, max )
	if ( !zone ) then return end

	net.Start( "PRK_Floor_Grass" )
		net.WriteFloat( zone )
		net.WriteVector( pos )
		net.WriteVector( min )
		net.WriteVector( max )
	net.Send( ply )
end

function PRK_Send_Floor_Plant( ply, zone, tab )
	if ( !zone ) then return end

	local count = #tab
	net.Start( "PRK_Floor_Plant" )
		net.WriteFloat( zone )
		net.WriteFloat( count )
		for k, plant in pairs( tab ) do
			net.WriteFloat( plant[1] )
			net.WriteVector( plant[2] )
			net.WriteAngle( plant[3] )
			net.WriteFloat( plant[4] )
			net.WriteFloat( plant[5] )
		end
	net.Send( ply )
end

function PRK_Send_Floor_Grid( ply, zone )
	if ( !zone ) then return end
	if ( !PRK_Floor_Grid[zone] ) then return end

	net.Start( "PRK_Floor_Grid" )
		net.WriteFloat( zone )
		net.WriteTable( PRK_Floor_Grid[zone] )
		net.WriteTable( PRK_RoomConnections[zone] )
	net.Send( ply )
end

-- Update all floors when a player moves into a zone
function PRK_Floor_MoveToZone( ply, zone )
	print( "move to zone floor" )
	if ( PRK_Floors[zone] ) then
		PRK_Send_Floor_Grass_Clear( ply )
		for k, floor in pairs( PRK_Floors[zone] ) do
			PRK_Send_Floor_Grass( ply, zone, floor[1], floor[2], floor[3] )
		end
		PRK_Send_Floor_Plant( ply, zone, PRK_Floor_Plants[zone] )
		PRK_Send_Floor_Grid( ply, zone )
	end
end

function PRK_Floor_ResetZone( zone )
	PRK_Floors[zone] = {}
	PRK_Floor_Plants[zone] = {}
	PRK_Floor_Grid[zone] = {}
	PRK_RoomConnections[zone] = {}
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
	timer.Simple( PRK_Gen_FloorDeleteTime, function()
		if ( self and self:IsValid() ) then
			-- Store position for visuals
			local min, max = self:GetRotatedCollisionBounds()
			-- print( self.Zone )
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
			self:StoreGrid()

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

			local min, max = self:GetRotatedCollisionBounds()
			local sca = Vector( max.x / PRK_Plate_Size * 2, max.y / PRK_Plate_Size * 2, 1 )
			local precision = 10
			local amount = math.floor( math.random( PRK_Grass_Mesh_CountRange[1] * precision, PRK_Grass_Mesh_CountRange[2] * precision ) / precision * ( sca.x + sca.y ) )
			for i = 1, amount do
				local ind = math.random( 1, #PRK_Floor_Models )
				table.insert( PRK_Floor_Plants[self.Zone], PRK_GetPlantTable( ind, self:GetPos() + Vector( math.random( min.x, max.x ), math.random( min.y, max.y ), math.random( min.z, max.z ) ) ) )
			end
		else
			timer.Simple( between, function() createplants() end )
		end
	end
	createplants()
end

function ENT:StoreGrid()
	local between = 1
	local function storegrid()
		if ( self.Zone != nil and PRK_Zones and PRK_Zones[self.Zone] ) then
			if ( !PRK_Floor_Grid ) then
				PRK_Floor_Grid = {}
			end
			if ( !PRK_Floor_Grid[self.Zone] ) then
				PRK_Floor_Grid[self.Zone] = {}
			end

			-- Find each grid square by dividing the bounds by the base cell size
			local size = PRK_Plate_Size
			local pos = PRK_Zones[self.Zone].pos - self:GetPos()
			local min, max = self:GetRotatedCollisionBounds()
				min = ( min - pos ) / size
					min.x = math.Round( min.x )
					min.y = math.Round( min.y )
				max = ( max - pos ) / size
					max.x = math.Round( max.x )
					max.y = math.Round( max.y )
			local dir = ( max - min ):GetNormalized()
				dir.x = math.sign( dir.x )
				dir.y = math.sign( dir.y )
			for x = 0, math.abs( min.x - max.x ) do
				for y = 0, math.abs( min.y - max.y ) do
					local gridx = min.x + dir.x * x
					local gridy = min.y + dir.y * y
					PRK_Floor_Grid[self.Zone][gridx] = PRK_Floor_Grid[self.Zone][gridx] or {}
					PRK_Floor_Grid[self.Zone][gridx][gridy] = self.PRK_Room
				end
			end
		else
			timer.Simple( between, function() storegrid() end )
		end
	end
	storegrid()
end

function ENT:GetRotatedCollisionBounds()
	local col = Color( 255, 255, 255, 255 )
	local min, max = self:GetCollisionBounds()
		local yaw = self:GetAngles().y
		if ( math.abs( yaw ) == 90 ) then
			local temp = min.x
			min.x = min.y
			min.y = temp
			local temp = max.x
			max.x = max.y
			max.y = temp
			col = Color( 0, 0, 255, 255 )
		elseif ( math.abs( yaw ) == 180 ) then
			min.x = -min.x
			min.y = -min.y
			max.x = -max.x
			max.y = -max.y
			col = Color( 255, 0, 0, 255 )
		end
	-- print( self:GetAngles() )
	debugoverlay.Box( self:GetPos(), min, max, 50, col )
	return min, max
end

function PRK_GetPlantTable( ind, pos )
	local rnd = PRK_Floor_Models[ind]
	local pos = pos + rnd[2]
	local ang = rnd[3] + Angle( math.random( -10, 10 ), math.random( 0, 360 ), math.random( -10, 10 ) )
	local sca = math.random( rnd[5][1] * 100, rnd[5][2] * 100 ) / 100
	local col = math.random( 1, #PRK_Floor_Colours )

	return {
		ind,
		pos,
		ang,
		sca,
		col
	}
end
