AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

local col_green = Color( 50, 255, 70, 255 )
local col_grey = Color( 171, 171, 171, 255 )

local off = 1.4
local offbig = 6
local models = {
	{
		"models/PHXtended/tri1x1x1solid.mdl",
		Vector( -PRK_Plate_Size / 2, PRK_Plate_Size / 2, -PRK_Plate_Size ),
		Angle( 0, 0, 90 ),
		"models/shiny",
		col_grey,
	},
	{
		"models/hunter/plates/plate1x1.mdl",
		Vector( -off, -PRK_Plate_Size / 2 - off, -PRK_Plate_Size / 2 ),
		Angle( 90, 90, 0 ),
		"models/shiny",
		col_grey,
	},
	{
		"models/hunter/plates/plate1x1.mdl",
		Vector( -off, PRK_Plate_Size / 2 + off, -PRK_Plate_Size / 2 ),
		Angle( 90, 90, 0 ),
		"models/shiny",
		col_grey,
	},
	{
		"models/hunter/blocks/cube1x2x025.mdl",
		Vector( 0, -PRK_Plate_Size / 2 - offbig, 0 ),
		Angle( 0, 0, 90 ),
		"models/shiny",
		col_green,
	},
	{
		"models/hunter/blocks/cube1x2x025.mdl",
		Vector( 0, PRK_Plate_Size / 2 + offbig, 0 ),
		Angle( 0, 0, 90 ),
		"models/shiny",
		col_green,
	},
	{
		"models/hunter/plates/plate1x1.mdl",
		Vector( 0, 0, PRK_Plate_Size - off ),
		Angle( 0, 0, 0 ),
		"models/shiny",
		col_green,
	},
	{
		"models/props_c17/canister_propane01a.mdl",
		Vector( 10, 20, PRK_Plate_Size + 40 ),
		Angle( 180, -40, 40 ),
		"models/shiny",
		Color( 255, 255, 255, 255 ),
	},
}

PRK_Vendor_Stock = {
	["BULLET"]					= { 10, "prk_bullet_heavy" },
	["POTION"]					= { 15, "prk_potion", Spawn = function( self, ent, ply )
			ent:SetPotionType( "Health Potion" )
		end,
	},
	["CHAMBERS POTION"]			= { 20, "prk_potion", Spawn = function( self, ent, ply )
			ent:SetPotionType( "Chamber Potion" )
		end,
	},
	["GOLD POTION"]				= { 28, "prk_potion", Spawn = function( self, ent, ply )
			ent:SetPotionType( "Gold Potion" )
		end,
	},
	-- ["SPEED POTION"]			= { 0, "prk_potion", Spawn = function( self, ent, ply )
			-- ent:SetPotionType( "Speed Potion" )
		-- end,
	-- },
	-- ["DAMAGE POTION"]			= { 0, "prk_potion", Spawn = function( self, ent, ply )
			-- ent:SetPotionType( "Damage Potion" )
		-- end,
	-- },
	["BOOM BOTTLE"]				= { 2, "prk_potion", Spawn = function( self, ent, ply )
			ent:SetPotionType( "Boom" )
		end,
	},
	["MYSTERY POTION"]			= { 5, "prk_potion", Spawn = function( self, ent, ply )
			ent:SetPotionType()
			ent:SetColor( ColorRand() )
		end,
	},
	["HEAL"]					= { 10, "", Spawn = function( self, ent, ply )
			local heal = 2 -- One full heart = 2hp
			ply:SetHealth( math.min( ply:Health() + heal, ply:GetMaxHealth() ) )
		end,
		ExtraRequire = function( self, ply )
			return ( ply:Health() != ply:GetMaxHealth() )
		end,
	},
	-- ["BOMB"]					= { 10, "prk_bullet_heavy" },
	-- ["KNIFE"]					= { 30, "prk_bullet_heavy" },
}

sound.Add(
	{ 
		name = "prk_uimachine_hum",
		channel = CHAN_ITEM,
		level = 60,
		volume = 1.0,
		pitch = { 80, 120 },
		sound = "ambient/energy/electric_loop.wav"
	}
)

util.AddNetworkString( "PRK_UIMachine_Stock" )
util.AddNetworkString( "PRK_UIMachine_Select" )

function ENT:SendStock()
	net.Start( "PRK_UIMachine_Stock" )
		net.WriteEntity( self )
		local clientstock = table.shallowcopy( self.Stock )
			-- Remove non-number indexed entries before sending to client (quick fix so as not to send function values)
			for _, item in pairs( clientstock ) do
				local toremove = {}
				for k, v in pairs( item ) do
					if ( k != tonumber( k ) ) then
						table.insert( toremove, k )
					end
				end
				for k, v in pairs( toremove ) do
					clientstock[_][v] = nil
				end
			end
		net.WriteTable( clientstock )
	net.Broadcast()
end

net.Receive( "PRK_UIMachine_Select", function( len, ply )
	local self = net.ReadEntity()
	local selection = net.ReadString()

	self:TryVend( ply, selection )
end )

function ENT:Initialize()
	-- Visuals
	local dia = self.Scale
	self:SetModel( "models/props_phx/construct/metal_tube.mdl" )
	self:SetMaterial( "models/shiny", true )
	self:SetColor( col_green )
	-- Position correctly
	timer.Simple(
		1,
		function()
			-- To ground
			local pos = self:GetPos() + self:GetForward() * PRK_Plate_Size
			local tr = util.TraceLine( {
				start = pos,
				endpos = pos - Vector( 0, 0, 10000 ),
			} )
			self:SetPos( tr.HitPos + Vector( 0, 0, PRK_Plate_Size ) )

			-- To wall
			local pos = self:GetPos() - self:GetForward() * PRK_Plate_Size
			local tr = util.TraceLine( {
				start = pos,
				endpos = pos - self:GetForward() * 10000,
			} )
			self:SetPos( tr.HitPos + tr.HitNormal * PRK_Plate_Size / 2 )
			self:SetAngles( tr.HitNormal:Angle() )

			-- Unlink children for proper collision
			for k, v in pairs( self.Ents ) do
				if ( v and v:IsValid() ) then
					v:SetParent()
				end
			end
		end
	)

	-- Physics
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	local phys = self:GetPhysicsObject()
	if ( phys and phys:IsValid() ) then
		phys:EnableMotion( false )
	end

	-- Extra models
	local oldang = self:GetAngles()
	self:SetAngles( Angle() )
	self.Ents = {}
		for k, v in pairs( models ) do
			self:CreateEnt(
				"prop_physics",
				v[1],
				self:GetPos() + v[2],
				v[3],
				v[4],
				v[5]
			)
		end
	self:SetAngles( oldang )

	-- Variables
	self.MaxItems = 4
	self.PriceFlux = math.random( 80, 170 ) / 100
	local possiblestock = table.shallowcopy( PRK_Vendor_Stock )
	self.Stock = {}
		for i = 1, self.MaxItems do
			local item, rnd = table.Random( possiblestock )
				item[1] = math.Round( item[1] * self.PriceFlux )
			self.Stock[rnd] = table.shallowcopy( item )
			possiblestock[rnd] = nil
		end
	timer.Simple( 0.1, function() self:SendStock() end )

	self:EmitSound( "prk_uimachine_hum" )
end

function ENT:InitializeNewClient()
	self:SendStock()
end

function ENT:Think()
	

	-- self:NextThink( CurTime() )
	-- return true
end

function ENT:OnRemove()
	self:StopSound( "prk_uimachine_hum" )

	for k, v in pairs( self.Ents ) do
		if ( v and v:IsValid() ) then
			v:Remove()
		end
	end
end

function ENT:OnTakeDamage( dmg )
	
end

function ENT:TryVend( ply, selection )
	local function onfail()
		self.Entity:EmitSound( "npc/scanner/combat_scan3.wav" )
	end

	-- Check item is in stock
	local data = self.Stock[selection]
	if ( data == nil ) then
		onfail()
		return
	end

	-- Check player is within range
	local dist = self:GetPos():Distance( ply:GetPos() )
	if ( dist > self.MaxUseRange ) then
		onfail()
		return
	end

	-- Check for any extra requirements
	if ( data.ExtraRequire and !data:ExtraRequire( ply ) ) then
		onfail()
		return
	end

	-- Check player has enough money
	local money = ply:GetNWInt( "PRK_Money" )
	local price = data[1]
	if ( money >= price ) then
		-- Take money
		ply:SetNWInt( "PRK_Money", money - price )

		-- Spawn item
		local ent
		if ( data[2] != "" ) then
			ent = PRK_CreateEnt( data[2], nil, self:GetPos(), AngleRand(), true )
			ent:PhysWake()
			timer.Simple( 0.75, function()
				if ( ent and ent:IsValid() ) then
					local phys = ent:GetPhysicsObject()
					if ( phys and phys:IsValid() ) then
						local speed = 3
						local dir = ( ply:GetPos() - ent:GetPos() )
						local velocity = dir * phys:GetMass() * speed
						phys:ApplyForceCenter( velocity )
					end
				end
			end )
		end
		-- Extra spawn functionality
		if ( data.Spawn ) then
			data:Spawn( ent, ply )
		end

		self.Entity:EmitSound( "npc/scanner/combat_scan" .. math.random( 1, 2 ) .. ".wav" )
	else
		onfail()
	end
end

function ENT:CreateEnt( class, mod, pos, ang, mat, col, mov )
	local ent = PRK_CreateEnt( class, mod, pos, ang, mov )
		ent:SetParent( self )
		if ( mat ) then
			ent:SetMaterial( mat )
		end
		if ( col ) then
			ent:SetColor( col )
		end
		table.insert( self.Ents, ent )
	return ent
end
