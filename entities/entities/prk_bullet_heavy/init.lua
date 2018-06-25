AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

-- sound.Add(
	-- { 
		-- name = "prk_bullet_heavy_fly",
		-- channel = CHAN_ITEM,
		-- level = 75,
		-- volume = 1.0,
		-- pitch = { 140, 180 },
		-- sound = "weapons/physcannon/hold_loop.wav"
	-- }
-- )

sound.Add(
	{ 
		name = "prk_bullet_heavy_hit_surface",
		channel = CHAN_ITEM,
		level = 75,
		volume = 1.0,
		pitch = { 140, 180 },
		sound = "physics/concrete/concrete_impact_hard1.wav"
	}
)

local function trypickup( ent, colent )
	if ( colent:IsPlayer() ) then --and colent == ent.Owner ) then
		colent:SetNWInt( "PRK_ExtraAmmo", colent:GetNWInt( "PRK_ExtraAmmo" ) + 1 )
		-- colent:EmitSound( "friends/friend_join.wav" )
		colent:EmitSound( "garrysmod/content_downloaded.wav" )
		ent:Remove()
	end
end

local function tryjump( ent )
	if ( ent and ent:IsValid() ) then
		-- Play sound
		ent:EmitSound( "physics/metal/metal_grenade_impact_hard" .. math.random( 1, 3 ) .. ".wav" )

		-- Jump off ground
		local phys = ent:GetPhysicsObject()
		if ( phys and phys:IsValid() ) then
			local horizontal	= 100
			local vertical		= 5000
			phys:ApplyForceCenter( Vector( math.random( -1, 1 ) * horizontal, math.random( -1, 1 ) * horizontal, vertical ) )
		end

		timer.Simple( ent.JumpDelay, function() tryjump( ent ) end )
	end
end

-- States
local State
State = {
	Damage = {
		Start = function( self, ent )
			-- print( "dmg" )
		end,
		Think = function( self, ent )
			
		end,
		Collide = function( self, ent, colent )
		
		end,
		End = function( self, ent )
			
		end,
	},
	Pickup = {
		Start = function( self, ent )
			-- print( "pck up" )
			timer.Simple( ent.JumpDelay, function() tryjump( ent ) end )
		end,
		Think = function( self, ent )
			for k, colent in pairs( ents.FindInSphere( ent:GetPos(), 50 ) ) do
				trypickup( ent, colent )
			end
		end,
		Collide = function( self, ent, colent )
			trypickup( ent, colent )
		end,
		End = function( self, ent )
			
		end,
	},
}

function ENT:Initialize()
	-- Visuals
	local dia = self.Scale
	self:SetModel( "models/Items/AR2_Grenade.mdl" )
	self:SetMaterial( "models/shiny", true )
	self:SetColor( Color( 50, 50, 70, 255 ) )
	self:SetModelScale( dia, 0 )
	self:DrawShadow( false )

	-- Physics
	dia = dia * 2
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
	self.Damage = 1
	self.Collide = 0
	self.MaxDamageCollide = 1
	self.JumpDelay = 4

	-- Precache missile noises
	-- util.PrecacheSound( "weapons/physcannon/hold_loop.wav" )
	util.PrecacheSound( "buttons/lever7.wav" )

	-- Initialise
	self:StartState( State.Damage )
end

function ENT:Think()
	self:ThinkState()

	self:NextThink( CurTime() )
	return true
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

	-- Slow down
	local speed = 1
	local phys = self:GetPhysicsObject()
	if ( phys and IsValid( phys ) ) then
		phys:SetVelocity( phys:GetVelocity() / 3 )
		speed = phys:GetVelocity():LengthSqr()
	end

	-- Apply damage/force
	if ( self.State == State.Damage and ent != self.Owner ) then
		local mult = 1
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
	end

	-- State specific collision logic
	self.State:Collide( self.Entity, ent )

	-- Count collisions before it becomes a pickup rather than a projectile
	self.Collide = self.Collide + 1
	if ( self.Collide == self.MaxDamageCollide ) then
		self:StartState( State.Pickup )
		if ( self.DamageEndCallback ) then
			self:DamageEndCallback()
		end
	end

	-- Play sound
	local maxspeed = 100000
	speed = math.min( 1, speed / maxspeed )
	self:EmitSound( "physics/concrete/concrete_impact_hard1.wav", 75, math.random( 180, 200 ), 1 * speed )

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
	-- self:SetVelocity( velocity * 1000000000 )
	local phys = self:GetPhysicsObject()
	if ( phys and IsValid( phys ) ) then
		phys:ApplyForceCenter( velocity )
		phys:EnableGravity( gravity )
		phys:SetMaterial( "gmod_bouncy" )
	end
	self:SetGravity( 1000 )
	self:SetAngles( velocity:Angle() )
	-- self:EmitSound( "prk_bullet_heavy_fly" )
end

function ENT:StartState( state )
	if ( self.State ) then
		self:EndState()
	end
	self.State = state
	self.State:Start( self )
end

function ENT:ThinkState()
	if ( self.State ) then
		self.State:Think( self )
	end
end

function ENT:EndState()
	self.State:End( self )
	self.State = nil
end
