AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

local DebrisModels = {
	"models/XQM/quad1.mdl",
	"models/XQM/quad2.mdl",
	"models/XQM/quad3.mdl",
	"models/XQM/rhombus1.mdl",
	"models/XQM/rhombus2.mdl",
	"models/XQM/triangle1x1.mdl",
	"models/XQM/triangle1x2.mdl",
	"models/XQM/triangle2x2.mdl",
	"models/XQM/trianglelong1.mdl",
	"models/XQM/trianglelong2.mdl",
	"models/XQM/trianglelong3.mdl",
	"models/XQM/trianglelong4.mdl",
}

function ENT:Initialize()
	-- Visuals
	self:SetModel( "models/hunter/blocks/cube1x1x05.mdl" )
	self:SetMaterial( "models/shiny", true )
	self:SetColor( Color( 255, 200, 20, 255 ) )

	-- Physics
	self:SetSolid( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NONE )
	self:PhysicsInit( SOLID_VPHYSICS )
	local phys = self:GetPhysicsObject()
	if ( phys and phys:IsValid() ) then
		phys:EnableMotion( false )
	end

	-- Variables
	self.Collide = 0
end

function ENT:Think()
	self:NextThink( CurTime() )
	return true
end

function ENT:OnTakeDamage( dmg )
	-- Destroy anything linked
	

	-- Play sound
	local sounds = {
		"physics/metal/metal_box_break1.wav",
		"physics/wood/wood_crate_break1.wav",
		"physics/wood/wood_crate_break2.wav",
		"physics/wood/wood_crate_break3.wav",
		"physics/wood/wood_crate_break4.wav",
	}
	local sound = sounds[math.random( 1, #sounds )]
	self:EmitSound( sound, 75, math.random( 140, 170 ) )

	-- Spawn debris
	local debris = math.random( 3, 5 )
	for i = 1, debris do
		local prop = PRK_CreateEnt( "prk_debris", DebrisModels[math.random( 1, #DebrisModels )], self:GetPos() + Vector( 0, 0, 10 ), AngleRand(), true )
			local phys = prop:GetPhysicsObject()
			if ( phys and phys:IsValid() ) then
				phys:SetVelocity( VectorRand() * 200 )
			end
		timer.Simple( 5, function() prop:Remove() end )
	end

	-- Destroy this
	self:Remove()
end

function ENT:PhysicsCollide( colData, collider )
	
end
