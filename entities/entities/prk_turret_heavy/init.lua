AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

function ENT:Initialize()
	-- Visuals
	self:SetModel( "models/hunter/blocks/cube1x1x05.mdl" )
	self:SetMaterial( "models/shiny", true )
	self:SetColor( Color( 181, 181, 200, 255 ) )

	-- Physics
	self:SetSolid( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NONE )
	self:PhysicsInit( SOLID_VPHYSICS )
	local phys = self:GetPhysicsObject()
	if ( phys and phys:IsValid() ) then
		phys:EnableMotion( false )
	end

	-- Parts
	local size = PRK_Plate_Size
	local hsize = size / 2
	local oldang = self:GetAngles()
	self:SetAngles( Angle() )
	self.Ents = {}
		self.Weakpoint = self:CreateEnt(
			"prk_enemy_weakpoint",
			"",
			self:GetPos() + Vector( 50, 0, 0 ),
			Angle()
		)
		self.Weakpoint:Attach( self )
		self.Rotator = self:CreateEnt(
			"prop_physics",
			"models/hunter/blocks/cube025x025x025.mdl",
			self:GetPos() + Vector( 0, 0, 0 ),
			Angle( 0, 0, 0 )
		)
		self.Neck = self:CreateEnt(
			"prop_physics",
			"models/hunter/blocks/cube025x150x025.mdl",
			self:GetPos() + Vector( hsize * 0.25, hsize * 0.25, hsize ),
			Angle( 0, 0, 90 )
		)
		self.Neck:SetParent( self.Rotator )
		self.Head = self:CreateEnt(
			"prop_physics",
			"models/hunter/blocks/cube1x1x025.mdl",
			self:GetPos() + Vector( 0, 0, size ),
			Angle( 0, 0, 0 )
		)
		self.Head:SetParent( self.Neck )
		self.Barrel = self:CreateEnt(
			"prop_physics",
			"models/hunter/blocks/cube025x025x025.mdl",
			self:GetPos() + Vector( hsize, 0, size ),
			Angle( 45, 90, 0 )
		)
		self.Barrel:SetParent( self.Head )
	self:SetAngles( oldang )
	-- Unparent neck
	self.Rotator:SetParent( nil )
	self.Weakpoint:SetParent( nil )

	-- Variables
	self.TimeFire = 2
end

function ENT:Think()
	-- Find target
	self.Target = ents.FindByClass( "npc_*" )[1]

	-- If first then deploy upwards
	

	-- Rotate towards target
	local dir = ( self.Target:GetPos() - self:GetPos() ):GetNormalized()
	self.Rotator:SetAngles( Angle( 0, dir:Angle().y, 0 ) )

	-- Fire if facing
	if ( !self.NextFire or self.NextFire <= CurTime() ) then
		local bullet = ents.Create( "prk_bullet_heavy" )
		bullet:Spawn()
			-- Old code to launch from barrel
			bullet:Launch(
				self.Barrel:GetPos(),
				( self.Target:GetPos() - self:GetPos() ):GetNormalized() * 50000
			)
		bullet.Owner = self.Owner
		timer.Simple( 2, function()
			if ( bullet and bullet:IsValid() ) then
				bullet:Remove()
			end
		end )

		self.NextFire = CurTime() + self.TimeFire
	end

	self:NextThink( CurTime() )
	return true
end

function ENT:OnRemove()
	for k, v in pairs( self.Ents ) do
		if ( v and v:IsValid() ) then
			v:Remove()
		end
	end
end

function ENT:CreateEnt( class, mod, pos, ang, mov )
	local ent = PRK_CreateEnt( class, mod, pos, ang, mov )
		ent:SetParent( self )
		table.insert( self.Ents, ent )
	return ent
end
