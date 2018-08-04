AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

local DebrisModels = {
	"models/props_wasteland/rockgranite02c.mdl",
	"models/props_wasteland/rockgranite03a.mdl",
	"models/props_wasteland/rockgranite03b.mdl",
	"models/props_wasteland/rockgranite03c.mdl",
}

function ENT:Initialize()
	-- Visuals
	self:SetModel( "models/props_wasteland/rockcliff01f.mdl" )
	self:SetMaterial( "models/shiny", true )
	self:SetColor( Color( 171, 171, 171, 255 ) )

	-- Physics
	self:SetSolid( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NONE )
	self:PhysicsInit( SOLID_VPHYSICS )
	local phys = self:GetPhysicsObject()
	if ( phys and phys:IsValid() ) then
		phys:EnableMotion( false )
	end

	-- Variables
	self.PRK_Health = 3
end

function ENT:OnTakeDamage( dmg )
	self.PRK_Health = self.PRK_Health - 1

	if ( self.PRK_Health <= 0 ) then
		-- Destroy anything linked
		if ( self.Attached and self.Attached:IsValid() ) then
			self.Attached:Remove()
		end

		-- Play sound
		local pos = self:GetPos()
		timer.Simple( 0.02, function ()
			local sounds = {
				-- "physics/concrete/boulder_impact_hard1.wav",
				-- "physics/concrete/boulder_impact_hard2.wav",
				-- "physics/concrete/boulder_impact_hard3.wav",
				-- "physics/concrete/boulder_impact_hard4.wav",
				"physics/wood/wood_panel_impact_hard1.wav",
			}
			local soundfile = sounds[math.random( 1, #sounds )]
			-- self:EmitSound( sound, 75, math.random( 140, 170 ) )
			sound.Play( soundfile, pos, 75, math.random( 80, 100 ) )
		end )

		-- Spawn debris
		local debris = math.random( 3, 5 )
		for i = 1, debris do
			local prop = PRK_CreateEnt( "prk_debris", DebrisModels[math.random( 1, #DebrisModels )], self:GetPos() + Vector( 0, 0, 10 ), AngleRand(), true )
			prop:SetColor( self:GetColor() )
			local phys = prop:GetPhysicsObject()
			if ( phys and phys:IsValid() ) then
				phys:SetVelocity( VectorRand() * 200 )
			end
		end

		-- Destroy this
		self:Remove()
	else
		-- Delay a fraction so it can be heard after firing
		timer.Simple( 0.02, function ()
			if ( self and self:IsValid() ) then
				local sounds = {
					-- "physics/concrete/concrete_impact_hard1.wav",
					-- "physics/concrete/concrete_impact_hard2.wav",
					-- "physics/concrete/concrete_impact_hard3.wav",
					"physics/wood/wood_panel_impact_hard1.wav"
				}
				local sound = sounds[math.random( 1, #sounds )]
				self:EmitSound( sound, 100, math.random( 140, 170 ) )
			end
		end )
	end
end

function ENT:PhysicsCollide( colData, collider )
	
end

function ENT:Attach( ent )
	self.Attached = ent
end
