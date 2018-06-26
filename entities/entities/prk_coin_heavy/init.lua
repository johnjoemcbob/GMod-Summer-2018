AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

local function trypickup( ent, colent )
	if ( colent:IsPlayer() ) then
		-- colent:SetNWInt( "PRK_ExtraAmmo", colent:GetNWInt( "PRK_ExtraAmmo" ) + 1 )
		colent:SetNWInt( "PRK_Money", colent:GetNWInt( "PRK_Money" ) + 1 )
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
			local horizontal	= 50
			local vertical		= 200
			local angle			= 5000
			phys:ApplyForceCenter( Vector( math.random( -1, 1 ) * horizontal, math.random( -1, 1 ) * horizontal, vertical ) )
			phys:AddAngleVelocity( VectorRand() * angle )
		end

		timer.Simple( math.random( ent.JumpDelay[1], ent.JumpDelay[2] ), function() tryjump( ent ) end )
	end
end

-- States
local State
State = {
	Pickup = {
		Start = function( self, ent )
			-- print( "pck up" )
			timer.Simple( math.random( ent.JumpDelay[1], ent.JumpDelay[2] ), function() tryjump( ent ) end )
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
	self:SetModel( "models/props_c17/clock01.mdl" )
	self:SetMaterial( "models/shiny", true )
	self:SetColor( Color( 50, 50, 70, 255 ) )
	self:SetModelScale( dia, 0 )
	self:DrawShadow( false )

	-- Physics
	self:SetCollisionGroup( COLLISION_GROUP_PASSABLE_DOOR )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:PhysWake()

	-- Variables
	self.JumpDelay = { 4, 8 }

	-- Initialise
	self:StartState( State.Pickup )
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

	-- State specific collision logic
	self.State:Collide( self.Entity, ent )

	-- Play sound
	self:EmitSound( "physics/concrete/concrete_impact_hard1.wav", 75, math.random( 180, 200 ), 1 )

	-- Play particle effect
	local effectdata = EffectData()
		effectdata:SetOrigin( self:GetPos() )
		effectdata:SetNormal( self:GetUp() )
	util.Effect( "prk_hit", effectdata )
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
