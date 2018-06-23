--
-- Prickly Summer 2018
-- 03/06/18
--
-- Main Serverside
--

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "levelgen.lua" )
include( "shared.lua" )

function GM:Initialize()

end

function GM:InitPostEntity()
	self:GenerateLobby()
end

function GM:PlayerSpawn( ply )
	-- Init health
	local health = 6
	ply:SetMaxHealth( health )
	ply:SetHealth( health )

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
end

function GM:Think()
	
end

function GM:HandlePlayerJumping( ply, vel )
	return true
end

function GM:EntityTakeDamage( target, dmginfo )
	if ( target:IsPlayer() ) then
		dmginfo:ScaleDamage( 0.2 )
	end
end

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
