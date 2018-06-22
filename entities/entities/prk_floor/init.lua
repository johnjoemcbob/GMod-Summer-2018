AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

function ENT:Initialize()
	-- self:SetModel( "models/props_phx/construct/windows/window1x1.mdl" )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:PhysicsInit( SOLID_VPHYSICS )

	-- Freeze initial body
	local phys = self:GetPhysicsObject()
	if ( phys and phys:IsValid() ) then
		phys:EnableMotion( false )
	end
end

function ENT:Think()
	-- self:NextThink( CurTime() )
	-- return true
end
