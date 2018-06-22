AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

function ENT:Initialize()
	-- Visuals
	self:SetMaterial( "models/shiny", true )
	self:SetColor( Color( 255, 200, 20, 255 ) )

	-- Physics
	self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:PhysWake()
end

function ENT:Think()
	
end
