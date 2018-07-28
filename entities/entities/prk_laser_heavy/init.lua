AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

sound.Add(
	{ 
		name = "prk_laser_heavy_fly",
		channel = CHAN_ITEM,
		level = 75,
		volume = 1.0,
		pitch = { 140, 180 },
		sound = "weapons/fx/nearmiss/bulletltor12.wav"
	}
)

function ENT:Initialize()
	-- Visuals
	local dia = self.Scale
	self:SetModel( "models/hunter/blocks/cube025x1x025.mdl" )
	self:SetMaterial( "models/shiny", true )
	self:SetColor( Color( 50, 50, 70, 255 ) )
	self:SetModelScale( dia, 0 )
	self:DrawShadow( false )

	-- Physics
	dia = dia
	local min = Vector( -dia, -dia, -dia )
	local max = Vector( dia, dia, dia )
	self:SetCollisionBounds(
		min,
		max
	)
	self:SetSolid( SOLID_OBB )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetCollisionGroup( COLLISION_GROUP_PLAYER_MOVEMENT )
	-- self:PhysicsInit( SOLID_VPHYSICS )
	-- self:PhysicsInitSphere( dia )
	self:PhysicsInitBox( min, max )
	self:PhysWake()

	-- Variables
	self.Damage = 0.5
	self.Collide = 0
	self.MaxDamageCollide = 1

	-- Precache missile noises
	util.PrecacheSound( "buttons/lever7.wav" )
end

function ENT:Think()
	self:NextThink( CurTime() )
	return true
end

function ENT:OnRemove()
	self:StopSound( "prk_laser_heavy_fly" )
end

function ENT:OnTakeDamage( dmg )
	
end

function ENT:PhysicsCollide( colData, collider )
	self:CollideWithEnt( colData.HitEntity )
end

function ENT:CollideWithEnt( ent )
	if ( self.NextCollide and self.NextCollide > CurTime() ) then return end

	-- Don't collide a bunch with one bounce
	self.NextCollide = CurTime() + 0.2

	-- Apply damage/force
	local mult = 2
		-- testing/fun
		if ( ent:IsNPC() or ent:GetClass() == "prop_physics" ) then
			mult = 50
		end
	ent:TakeDamage( self.Damage * mult, self.Owner, self )

	-- testing/fun
	-- if ( ent:GetClass() == "prop_physics" and !(ent:IsNPC() or ent:IsPlayer()) ) then
		local phys = ent:GetPhysicsObject()
		if ( phys and IsValid( phys ) ) then
			phys:ApplyForceOffset( ( ent:GetPos() - self:GetPos() ):GetNormalized() * 50000, self:GetPos() )
		end
	-- end

	-- Count collisions before it becomes a pickup rather than a projectile
	self.Collide = self.Collide + 1
	if ( self.Collide == self.MaxDamageCollide ) then
		-- Callback after damaging (timer to avoid "Changing collision rules within a callback is likely to cause crashes!" warning)
		self:SetNoDraw( true )
		timer.Simple( 0.1, function()
			if ( self and self:IsValid() and self.DamageEndCallback ) then
				self:DamageEndCallback()
			end
		end )
	end

	-- Play sound
	self:EmitSound( "physics/glass/glass_impact_hard3.wav", 75, math.random( 180, 200 ), 1 )

	-- Play particle effect
	local effectdata = EffectData()
		effectdata:SetOrigin( self:GetPos() )
		effectdata:SetNormal( self:GetUp() )
	util.Effect( "prk_hit", effectdata )
end

function ENT:Launch( startpos, velocity, gravity )
	if ( gravity == nil ) then
		gravity = true
	end

	self.launch_vector = velocity
	self:SetPos( startpos )
	local phys = self:GetPhysicsObject()
	if ( phys and IsValid( phys ) ) then
		phys:ApplyForceCenter( velocity )
		phys:EnableGravity( gravity )
		phys:SetMaterial( "gmod_bouncy" )
	end
	self:SetGravity( 1000 )
	self:SetAngles( velocity:Angle() )
	self:EmitSound( "prk_laser_heavy_fly" )
end
