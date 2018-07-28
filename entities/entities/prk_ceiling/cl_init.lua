include( "shared.lua" )

function ENT:Initialize()
	-- Ceiling scale
	local min, max = self:GetCollisionBounds()
	local sca = Vector( max.x / PRK_Plate_Size * 2, max.y / PRK_Plate_Size * 2, 1 )
	local mat = Matrix()
		mat:Scale( sca )
	self:EnableMatrix( "RenderMultiply", mat )
	self:SetRenderBounds( min * 2, max * 2 )

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
end

function ENT:Draw()
	if ( !PlayerInZone( self, self.Zone ) ) then return end

	self:DrawModel()
end
