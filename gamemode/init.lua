--
-- Prickly Summer 2018
-- 03/06/18
--
-- Main Serverside
--

-- LUA Downloads
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

-- LUA Includes
include( "shared.lua" ) -- Must be first for globals
include( "levelgen.lua" )
include( "buffs.lua" )

-- Resource Downloads
function resource.AddDir( localdir )
	local srchpath = localdir .. "*"
	-- print( srchpath )
	local files, directories = file.Find( srchpath, "GAME" )
	for k, file in pairs( files ) do
		-- print( localdir .. file )
		resource.AddFile( localdir .. file )
	end
	for k, dir in pairs( directories ) do
		-- print( localdir )
		-- print( localdir .. dir )
		resource.AddDir( localdir .. dir .. "/" )
	end
end
print( "PRK" )
print( "----------------" )
print( "Add resources..." )
resource.AddDir( "gamemodes/prickly_summer_2018/content/" )
print( "Finish resources..." )
print( "-------------------" )

-- Net
util.AddNetworkString( "PRK_KeyValue" )
util.AddNetworkString( "PRK_TakeDamage" )
util.AddNetworkString( "PRK_Die" )

function SendKeyValue( ply, key, val )
	net.Start( "PRK_KeyValue" )
		net.WriteString( key )
		net.WriteString( val )
	net.Send( ply )
end

function SendTakeDamage( ply, amount, dir )
	net.Start( "PRK_TakeDamage" )
		net.WriteFloat( amount )
		net.WriteVector( dir )
	net.Send( ply )
end

function SendDie( ply, pos, ang )
	net.Start( "PRK_Die" )
		net.WriteVector( pos )
		net.WriteAngle( ang )
	net.Send( ply )
end

------------------------
  -- Gamemode Hooks --
------------------------
function GM:Initialize()

end

function GM:InitPostEntity()
	self:GenerateLobby()
end

function GM:PlayerSpawn( ply )
	ply:SetModel( "models/player/soldier_stripped.mdl" )
	local mats = {
		"phoenix_storms/wire/pcb_green",
		"phoenix_storms/wire/pcb_red",
		"phoenix_storms/wire/pcb_blue",
	}
	ply:SetMaterial( mats[math.random( 1, #mats )] )
	-- ply:SetMaterial( "phoenix_storms/wire/pcb_red" )
	-- ply:SetMaterial( "models/props_combine/tprings_globe" )
	-- ply:SetMaterial( "debug/env_cubemap_model" )
	-- ply:SetMaterial( "models/shadertest/shader5" )

	-- Init health
	local health = 6
	ply:SetMaxHealth( health )
	ply:SetHealth( health )

	-- Init money
	ply:SetNWInt( "PRK_Money", 0 )

	-- Init gun
	local wep = ply:Give( "prk_gun", true )
	wep:Initialize()

	-- Init speed
	ply:SetWalkSpeed( PRK_Speed )
	ply:SetRunSpeed( PRK_Speed )
	ply:SetMaxSpeed( PRK_Speed )

	-- Init jump
	ply:SetJumpPower( PRK_Jump )

	-- Init no crouch
	ply:SetViewOffsetDucked( ply:GetViewOffset() )
	local min, max = ply:GetHull()
	ply:SetHullDuck( min, max )

	-- Init no crosshair
	ply:CrosshairDisable()
    
    -- Reset buffs
    PRK_Buff_Register(ply)
end

function GM:Think()
	
end

function GM:HandlePlayerJumping( ply, vel )
	return true
end

local dmgnoises = {
	"npc/zombie/zombie_pain1.wav",
	"npc/zombie/zombie_pain2.wav",
	"npc/zombie/zombie_pain3.wav",
	"npc/zombie/zombie_pain4.wav",
	"npc/zombie/zombie_pain5.wav",
}
function GM:EntityTakeDamage( target, dmginfo )
	if ( target:IsPlayer() ) then
		if ( !string.find( dmginfo:GetInflictor():GetClass(), "prk" ) ) then
			dmginfo:ScaleDamage( 0.2 )
		end
		if ( dmginfo:GetDamageType() == DMG_CRUSH or dmginfo:GetDamageType() == DMG_FALL ) then
			dmginfo:ScaleDamage( 0 )
		end

		if ( dmginfo:GetDamage() > 0 ) then
			local dir = dmginfo:GetInflictor():GetPos() - target:GetPos()
				dir:Normalize()
			SendTakeDamage( target, dmginfo:GetDamage(), dir )

			-- Play sound
			PRK_EmitChainPitchedSound(
				target:Nick() .. "_PRK_Hurt",
				target,
				dmgnoises[math.random( 1, #dmgnoises )],
				75,
				0.5 + ( 0.25 / 2 * dmginfo:GetDamage() ),
				math.random( 230, 255 ),
				-30 * dmginfo:GetDamage(),
				nil,
				1
			)
		end
	end
end

function GM:DoPlayerDeath( ply, attacker, dmginfo )
	SendDie( ply, ply:EyePos(), ply:EyeAngles() )
	ply:SetPos( ply:EyePos() )
end

function GM:PlayerDeathSound()
	return true
end

function GM:OnNPCKilled( npc, attacker, inflictor )
	-- Testing / fun (only non-prickly NPCs)
	if ( string.find( npc:GetClass(), "prk_" ) ) then return end
	local coins = npc:GetMaxHealth() * PRK_Enemy_CoinDropMult
	for i = 1, coins do
		PRK_CreateEnt( "prk_coin_heavy", nil, npc:GetPos(), AngleRand(), true )
	end
end
-------------------------
  -- /Gamemode Hooks --
-------------------------

-- gateway
-- lid				models/hunter/blocks/cube025x2x025.mdl
-- head				models/hunter/blocks/cube1x4x1.mdl
-- pillar			models/hunter/blocks/cube1x4x1.mdl

function GM:GenerateLobby()
	local size = PRK_Plate_Size
	local hsize = size / 2

	-- Add walls
	local origin = Vector( 0, 0, -12289 )
	local amount = 2
	local function createwall( x, y, yaw )
		PRK_CreateEnt(
			"prk_wall",
			"models/hunter/plates/plate8x8.mdl",
			origin + Vector( size * 8 * y, size * 8 * x, hsize * 8 ),
			Angle( 90, yaw, 0 )
		)
	end
	for x = -amount, amount do
		for y = -amount, amount, amount * 2 do
			createwall( x, y, 0 )
		end
	end
	for y = -amount, amount do
		for x = -amount, amount, amount * 2 do
			createwall( x, y, 90 )
		end
	end

	-- Add floor
	local origin = origin + Vector( 0, 0, -hsize * 8 )
	local function createfloor( x, y )
		local floor = PRK_CreateEnt(
			"prk_floor",
			"models/hunter/plates/plate8x8.mdl",
			origin + Vector( size * 8 * y, size * 8 * x, hsize * 8 ),
			Angle( 0, 0, 0 )
		)
		floor:DrawShadow( false )
		floor:SetMaterial( "models/rendertarget" )
		floor:SetColor( 0, 0, 0, 255 )
	end
	for x = -amount, amount do
		for y = -amount, amount do
			createfloor( x, y, 0 )
		end
	end

	-- Add ceiling
	local origin = origin + Vector( 0, 0, size * 8 )
	local function createceil( x, y )
		local ceil = PRK_CreateProp(
			-- "prk_ceiling",
			"models/hunter/plates/plate8x8.mdl",
			origin + Vector( size * 8 * y, size * 8 * x, hsize * 8 ),
			Angle( 0, 0, 0 )
		)
		ceil:DrawShadow( false )
		ceil:SetMaterial( "models/rendertarget" )
		ceil:SetColor( 0, 0, 0, 255 )
	end
	for x = -amount, amount do
		for y = -amount, amount do
			createceil( x, y, 0 )
		end
	end
end

--------------
  -- Util --
--------------
-- Create a physics prop which is frozen by default
-- Model (String), Position (Vector), Angle (Angle), Should Move? (bool)
function PRK_CreateProp( mod, pos, ang, mov )
	local ent = ents.Create( "prop_physics" )
		ent:SetModel( mod )
		ent:SetPos( pos )
		ent:SetAngles( ang )
		ent:Spawn()
		if ( !mov ) then
			local phys = ent:GetPhysicsObject()
			if ( phys and phys:IsValid() ) then
				phys:EnableMotion( false )
			end
		end
	return ent
end

-- Create an ent which is frozen by default
-- Class (String), Model (String), Position (Vector), Angle (Angle), Should Move? (bool)
function PRK_CreateEnt( class, mod, pos, ang, mov )
	local ent = ents.Create( class )
		if ( mod ) then
			ent:SetModel( mod )
		end
		ent:SetPos( pos )
		ent:SetAngles( ang )
		ent:Spawn()
		if ( !mov ) then
			local phys = ent:GetPhysicsObject()
			if ( phys and phys:IsValid() ) then
				phys:EnableMotion( false )
			end
		end
	return ent
end
---------------
  -- /Util --
---------------
