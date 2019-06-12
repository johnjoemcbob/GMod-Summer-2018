AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

util.AddNetworkString( "PRK_Wall_Combined" )

-- Send to all clients to render walls
function ENT:SendWallCombined()
	net.Start( "PRK_Wall_Combined" )
		net.WriteEntity( self )
		net.WriteTable( self.Walls )
	net.Broadcast()
end

function ENT:Initialize()
	-- Find all existing walls of same zone and store
	local zone = 1
	self.Walls = {}
	for k, wall in pairs( ents.FindByClass( "prk_wall" ) ) do
		if ( wall.Zone == zone ) then
			table.insert( self.Walls, {
				Ent = wall,
				Min = wall:OBBMins(),
				Max = wall:OBBMaxs(),
			} )
		end
	end
	if ( #self.Walls == 0 ) then
		-- Debug for later when I inevitably forget to set zone
		print( "No walls to combine for zone " .. zone )
	else
		print( "Found " .. #self.Walls .. " walls to combine..." )

		-- Combine all wall physics meshes
		local collisions = {}
			for k, wall in pairs( self.Walls ) do
				local min = wall.Ent:GetPos() + self:GetRotated( wall, wall.Min ) - self:GetPos()
				local max = wall.Ent:GetPos() + self:GetRotated( wall, wall.Max ) - self:GetPos()
				table.insert( collisions, {
					Vector( min.x, min.y, min.z ),
					Vector( min.x, min.y, max.z ),
					Vector( min.x, max.y, min.z ),
					Vector( min.x, max.y, max.z ),
					Vector( max.x, min.y, min.z ),
					Vector( max.x, min.y, max.z ),
					Vector( max.x, max.y, min.z ),
					Vector( max.x, max.y, max.z ),
				} )
				debugoverlay.Box(
					Vector(),
					min + self:GetPos(),
					max + self:GetPos(),
					10,
					Color( 255, 255, 255, 255 )
				)
			end
		self:PhysicsInitMultiConvex( collisions )

		-- Remove old walls
		for k, wall in pairs( self.Walls ) do
			-- wall.Ent:Remove()
			-- local phys = wall.Ent:GetPhysicsObject()
			-- if ( phys and phys:IsValid() ) then
				-- phys:EnableCollisions( false )
			-- end
			wall.Ent:SetPos( wall.Ent:GetPos() + Vector( 0, 0, 300 ) )
		end

		-- Send walls to client for visualisation
		self:SendWallCombined()
	end

	-- Set up solidity and movetype
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	-- Enable custom collisions on the entity
	self:EnableCustomCollisions( true )

	-- Freeze initial body
	local phys = self:GetPhysicsObject()
	if ( phys and phys:IsValid() ) then
		phys:EnableMotion( false )
	end
end

-- Since walls up are facing along the horizontal axis
function ENT:GetRotated( wall, point )
	return point -- temp test
	
	
	local ret = point
		if ( wall.Ent:GetAngles().y == 0 ) then
			local temp = ret.z
			ret.z = ret.y
			ret.y = temp
		else
			-- local temp = ret.x
			-- ret.x = ret.y
			-- ret.y = temp
			local temp = ret.z
			ret.z = ret.y
			ret.y = temp
		end
	return ret
end
