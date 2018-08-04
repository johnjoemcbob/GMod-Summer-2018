AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

PRK_PotionTypes = {
	["Health Potion"] = {
		Colour = Color( 255, 100, 100, 255 ),
		Drink = function( self, ent, ply )
			-- if ( ply:Health() != ply:GetMaxHealth() ) then
				local heal = 2 -- One full heart = 2hp
				ply:SetHealth( math.min( ply:Health() + heal, ply:GetMaxHealth() ) )
				ply:EmitSound( "npc/combine_gunship/gunship_moan.wav", 75, math.random( 220, 235 ) )
				return true
			-- end
		end,
	},
	["Gold Potion"] = {
		Colour = Color( 255, 215, 0, 255 ),
		Drink = function( self, ent, ply )
			-- if ( ply:Health() != ply:GetMaxHealth() ) then
				local heal = 4 -- One full heart = 2hp
				ply:SetHealth( math.min( ply:Health() + heal, ply:GetMaxHealth() ) )
				ply:EmitSound( "npc/combine_gunship/gunship_moan.wav", 75, math.random( 200, 215 ) )
				return true
			-- end
		end,
	},
	["Chamber Potion"] = {
		Colour = Color( 100, 255, 255, 255 ),
		Drink = function( self, ent, ply )
			PRK_Buff_Add( ply, PRK_BUFFTYPE_PLAYER_CHAMBERS, 1 )
				ply:EmitSound( "npc/combine_soldier/vo/readyweapons.wav", 75, math.random( 170, 190 ) )
			return true
		end,
	},
	["Speed Potion"] = {
		Colour = Color( 100, 255, 100, 255 ),
		Drink = function( self, ent, ply )
			PRK_Buff_Add( ply, PRK_BUFFTYPE_PLAYER_SPEED, 1 )
			return true
		end,
	},
	["Speed Poison"] = {
		Colour = Color( 100, 255, 100, 255 ),
		Drink = function( self, ent, ply )
			PRK_Buff_Remove( ply, PRK_BUFFTYPE_PLAYER_SPEED, 1 )
			return true
		end,
	},
	["Damage Potion"] = {
		Colour = Color( 255, 100, 255, 255 ),
		Drink = function( self, ent, ply )
			PRK_Buff_Add( ply, PRK_BUFFTYPE_BULLET_DMG, 1 )
			return true
		end,
	},
	["Damage Poison"] = {
		Colour = Color( 100, 255, 100, 255 ),
		Drink = function( self, ent, ply )
			PRK_Buff_Remove( ply, PRK_BUFFTYPE_BULLET_DMG, 1 )
			return true
		end,
	},
	["Poison"] = {
		Colour = Color( 40, 40, 40, 255 ),
		Drink = function( self, ent, ply )
			PRK_OverrideDeathMessage( ply, {
				"POISON",
				"YOUR OWN CURIOSITY",
				"YOUR OWN STUPIDITY",
				"SPOILED BITER MILK",
			} )
			ply:TakeDamage( 1, ent, ent )
			PRK_OverrideDeathMessage( ply, nil )
			return true
		end,
	},
	["Greater Poison"] = {
		Colour = Color( 10, 10, 10, 255 ),
		Drink = function( self, ent, ply )
			PRK_OverrideDeathMessage( ply, {
				"POISON",
				"YOUR OWN CURIOSITY",
				"YOUR OWN STUPIDITY",
				"SPOILED BITER MILK",
			} )
			ply:TakeDamage( 2, ent, ent )
			PRK_OverrideDeathMessage( ply, nil )
			return true
		end,
	},
	["Boom"] = {
		Colour = Color( 0, 0, 0, 255 ),
		Drink = function( self, ent, ply )
			PRK_OverrideDeathMessage( player.GetAll(), {
				"AN EXPLOSION IN A BOTTLE",
				"BOTTLED SPLODER ESSENCE",
				"A BIG BOOM",
				"YOUR OWN CURIOSITY",
				"YOUR OWN STUPIDITY",
				"ESPECIALLY POTENT WHISKEY",
			} )
			PRK_Explosion( ent, ent:GetPos(), 200 )
			PRK_OverrideDeathMessage( player.GetAll(), nil )
			-- ply:TakeDamage( ply:GetMaxHealth(), ent, ent )
			return true
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

function ENT:InitializeNewClient()
	self:SendPotionType( table.KeyFromValue( PRK_PotionTypes, self.PotionType ) )
	print( "init potion late!" )
end

function ENT:Use( ply, caller, useType, value )
	if ( self:GetPos():Distance( ply:GetPos() ) > self.MaxUseRange ) then return end

	local consumed = self.PotionType:Drink( self, ply )
	if ( consumed ) then
		ply:EmitSound( "npc/barnacle/barnacle_gulp1.wav", 75, math.random( 150, 200 ) )
		SendDrink( ply )
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
	-- Could use table.GetKeys instead, but this is already working this way
	if ( !type ) then
		-- Choose a random one if not set
		local count = 0
			for k, v in pairs( PRK_PotionTypes ) do
				count = count + 1
			end
		local rnd = math.random( 1, count )
		local index = 1
		for k, v in pairs( PRK_PotionTypes ) do
			if ( index == rnd ) then
				type = k
			end
			index = index + 1
		end
	end
	self.PotionType = PRK_PotionTypes[type]
	self:SetColor( self.PotionType.Colour )
	self:SendPotionType( type )
end
