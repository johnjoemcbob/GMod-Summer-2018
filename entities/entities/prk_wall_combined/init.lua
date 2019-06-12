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
			-- Initial pos
			if ( self:GetPos() == Vector() ) then
				self.TargetPos = wall:GetPos()
				self:SetPos( self.TargetPos )
			end

			-- Correct for wrong angle and store bounds for combination
			local mins = wall:OBBMins()
			local maxs = wall:OBBMaxs()
			if ( math.abs( wall:GetAngles().y ) == 90 ) then
				local temp = mins.x
				mins.x = mins.y
				mins.y = temp
				local temp = maxs.x
				maxs.x = maxs.y
				maxs.y = temp
			end
			table.insert( self.Walls, {
				Ent = wall,
				Min = wall:GetPos() + mins - self:GetPos(),
				Max = wall:GetPos() + maxs - self:GetPos(),
			} )
			-- print( self:GetPos() )
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
				local min = ( wall.Min )
				local max = ( wall.Max )
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
			end
		self:PhysicsInitMultiConvex( collisions )

		-- Remove old walls
		for k, wall in pairs( self.Walls ) do
			wall.Ent:Remove()
			-- local phys = wall.Ent:GetPhysicsObject()
			-- if ( phys and phys:IsValid() ) then
				-- phys:EnableCollisions( false )
			-- end
			-- wall.Ent:SetPos( wall.Ent:GetPos() + Vector( 0, 0, 300 ) )
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
	
	-- self:SetPos( self:GetPos() + self:GetUp() * -100 )
end

function ENT:Think()
	-- self:SetPos( self:GetPos() + self:GetUp() * math.sin( CurTime() ) * 100 )
	if ( self.TargetPos != nil ) then
		self:SetPos( self.TargetPos )
	end
end
