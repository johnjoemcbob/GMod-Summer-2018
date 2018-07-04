AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

PRK_PotionTypes = {
	["Health Potion"] = {
		Colour = Color( 255, 100, 100, 255 ),
		Drink = function( self, ply )
			if ( ply:Health() != ply:GetMaxHealth() ) then
				local heal = 2 -- One full heart = 2hp
				ply:SetHealth( math.min( ply:Health() + heal, ply:GetMaxHealth() ) )
				ply:EmitSound( "npc/combine_gunship/gunship_moan.wav", 75, math.random( 220, 235 ) )
				return true
			end
		end,
	},
	["Gold Potion"] = {
		Colour = Color( 255, 215, 0, 255 ),
		Drink = function( self, ply )
			if ( ply:Health() != ply:GetMaxHealth() ) then
				local heal = 4 -- One full heart = 2hp
				ply:SetHealth( math.min( ply:Health() + heal, ply:GetMaxHealth() ) )
				return true
			end
		end,
	},
}

util.AddNetworkString( "PRK_Potion_Type" )

function ENT:SendPotionType( type )
	net.Start( "PRK_Potion_Type" )
		net.WriteEntity( self )
		net.WriteString( type )
	net.Broadcast()
end

function ENT:Initialize()
	-- Visuals
	-- self:SetColor( Color( 100, 100, 255, 255 ) ) -- Potion liquid colour
	self:DrawShadow( false )

	-- Physics
	self:SetModel( "models/props_junk/TrafficCone001a.mdl" )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:PhysWake()
	self:SetPos( self:GetPos() + Vector( 0, 0, 15 ) )

	-- Base potion type
	self.PotionType = PRK_PotionTypes["Health Potion"]
	self:SetColor( self.PotionType.Colour )

	-- Variables
	-- self.
end

function ENT:Think()
	

	self:NextThink( CurTime() )
	return true
end

function ENT:Use( ply, caller, useType, value )
	if ( self:GetPos():Distance( ply:GetPos() ) > self.MaxUseRange ) then return end

	local consumed = self.PotionType:Drink( ply )
	if ( consumed ) then
		self:Remove()
	end
end

function ENT:PhysicsCollide( colData, collider )
	self:CollideWithEnt( colData.HitEntity )
end

function ENT:CollideWithEnt( ent )
	if ( self.NextCollide and self.NextCollide > CurTime() ) then return end

	-- Don't collide a bunch with one bounce
	self.NextCollide = CurTime() + 0.2

	-- Get speed
	local speed = 1
	local phys = self:GetPhysicsObject()
	if ( phys and IsValid( phys ) ) then
		speed = phys:GetVelocity():LengthSqr()
	end

	-- Play sound
	local maxspeed = 100000
		speed = math.min( 1, speed / maxspeed )
	self:EmitSound( "physics/glass/glass_impact_hard" .. math.random( 1, 3 ) .. ".wav", 75, math.random( 180, 200 ), 1 * speed )

	-- Play particle effect
	local effectdata = EffectData()
		effectdata:SetOrigin( self:GetPos() )
		effectdata:SetNormal( self:GetUp() )
	util.Effect( "prk_hit", effectdata )
end

function ENT:SetPotionType( type )
	self.PotionType = PRK_PotionTypes[type]
	self:SetColor( self.PotionType.Colour )
	self:SendPotionType( type )
end
