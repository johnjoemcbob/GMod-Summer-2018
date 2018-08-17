AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

function ENT:Initialize()
	-- Visuals
	self:SetModel( "models/props_foliage/oak_tree01.mdl" )
	self:SetMaterial( PRK_Material_Base, true )
	self:SetColor( Color( 20, 20, 20, 255 ) )

	-- Physics
	self:SetSolid( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NONE )
	self:PhysicsInit( SOLID_VPHYSICS )
	local phys = self:GetPhysicsObject()
	if ( phys and phys:IsValid() ) then
		phys:EnableMotion( false )
	end
end
