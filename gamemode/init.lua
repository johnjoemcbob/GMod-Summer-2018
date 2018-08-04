--
-- Prickly Summer 2018
-- 03/06/18
--
-- Main Serverside
--

-- LUA Downloads
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_editor_room.lua" )
AddCSLuaFile( "shared.lua" )

-- LUA Includes
include( "shared.lua" ) -- Must be first for globals
include( "levelgen.lua" )
include( "buffs.lua" )

-- Resource Downloads
local dir = "gamemodes/prickly_summer_2018/content/"
function resource.AddDir( localdir )
	local srchpath = localdir .. "*"
	-- print( srchpath )
	local files, directories = file.Find( srchpath, "GAME" )
	for k, file in pairs( files ) do
		local res = string.gsub( localdir .. file, dir, "" )
		-- print( res )
		resource.AddFile( res )
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
resource.AddDir( dir )
print( "Finish resources..." )
print( "-------------------" )

-- Net
util.AddNetworkString( "PRK_KeyValue" )
util.AddNetworkString( "PRK_TakeDamage" )
util.AddNetworkString( "PRK_Die" )
util.AddNetworkString( "PRK_Spawn" )
util.AddNetworkString( "PRK_Editor" )
util.AddNetworkString( "PRK_EditorExport" )

function SendKeyValue( ply, key, val )
	net.Start( "PRK_KeyValue" )
		net.WriteString( key )
		net.WriteString( val )
	net.Send( ply )
end

function SendTakeDamage( ply, amount, dir, pos )
	net.Start( "PRK_TakeDamage" )
		net.WriteEntity( ply )
		net.WriteFloat( amount )
		net.WriteVector( dir )
		net.WriteVector( pos )
	net.Broadcast()
end

function SendDie( ply, pos, ang, killname )
	net.Start( "PRK_Die" )
		net.WriteVector( pos )
		net.WriteAngle( ang )
		net.WriteString( killname )
	net.Send( ply )
end

function SendSpawn( ply, time )
	net.Start( "PRK_Spawn" )
		net.WriteFloat( time )
	net.Send( ply )
end

net.Receive( "PRK_Editor", function( len, ply )
	local toggle = net.ReadBool()

	ply.PRK_Editor = toggle
	if ( ply.PRK_Editor ) then
		ply.PRK_Editor_OldPos = ply:GetPos()
		ply:SetPos( PRK_Position_Nowhere )
	else
		ply:SetPos( ply.PRK_Editor_OldPos )
	end
	-- ply:Freeze( toggle )
	-- if ( toggle ) then
		-- ply:Lock()
	-- else
		-- ply:UnLock()
	-- end
end )

net.Receive( "PRK_EditorExport", function( len, ply )
	local content = net.ReadString()

	print( "receive content to save:" .. content )
	local dir = PRK_Path_Rooms
	local filename = ply:SteamID64() -- todo: client define file name, append to their steamID (so each player can store more than one room)
	print( dir )
	print( filename )
	file.CreateDir( dir )
	file.Write( dir .. filename .. ".txt", content )
end )

------------------------
  -- Gamemode Hooks --
------------------------
function GM:Initialize()

end

function GM:InitPostEntity()
	-- Hide sun
	local suns = ents.FindByClass( "env_sun" )
	for k, sun in pairs( suns ) do
		sun:SetKeyValue( "size", 0 )
		sun:SetKeyValue( "overlaysize", 0 )
	end

	-- Generate and connect world
	self:GenerateLobby()

	local gates = {
		{
			Vector( 0, 740, -12200 ),
			Angle( 0, 90, 0 ),
		},
		{
			Vector( 740, 0, -12200 ),
			Angle( 0, 0, 0 ),
		},
		{
			Vector( 0, -740, -12200 ),
			Angle( 0, -90, 0 ),
		},
		{
			Vector( -740, 0, -12200 ),
			Angle( 0, 180, 0 ),
		},
	}
	local function gen( num )
		math.randomseed( PRK_Gen_Seed )
		PRK_Gen( PRK_Zones[num].pos, num )
		math.randomseed( os.time() )

		-- Create gateway to link to this
		local ent = PRK_CreateEnt( "prk_gateway", nil, gates[num][1], gates[num][2] )
		ent:SetDestination( PRK_Zones[num].pos, num )
	end

	PRK_Zones = self:FlatgrassZones()
	timer.Simple( 1, function()
		gen( 1 )
	end )
end

function GM:PlayerInitialSpawn( ply )
	-- Send any required client data to the new client
	-- timer.Simple( 2, function()
		-- for k, v in pairs( ents.FindByClass( "prk_*" ) ) do
			-- if ( v.InitializeNewClient ) then
				-- v:InitializeNewClient()
			-- end
		-- end
	-- end )
end

function GM:MoveToZone( ply, zone )
	ply:SetNWInt( "PRK_Zone", zone )

	-- Reset player info
	self:PlayerSetup( ply )

	-- Floors
	PRK_Floor_MoveToZone( ply, zone )

	-- Request any entity client info
		-- Send any required client data to the new client
	timer.Simple( 2, function()
		for k, v in pairs( ents.FindByClass( "prk_*" ) ) do
			if ( v.InitializeNewClient ) then
				v:InitializeNewClient()
			end
		end
	end )
end

function GM:PlayerSpawn( ply )
	-- Reset to the lobby
	self:MoveToZone( ply, 0 )

	ply:SetModel( "models/player/soldier_stripped.mdl" )
	local mats = {
		"phoenix_storms/wire/pcb_green",
		"phoenix_storms/wire/pcb_red",
		"phoenix_storms/wire/pcb_blue",
	}
	-- ply:SetMaterial( mats[math.random( 1, #mats )] )
	ply:SetMaterial( "models/debug/debugwhite" )
	local cols = PRK_Colour_Player
	ply:SetColor( cols[math.random( 1, #cols )] )
	-- ply:SetMaterial( "phoenix_storms/wire/pcb_red" )
	-- ply:SetMaterial( "models/props_combine/tprings_globe" )
	-- ply:SetMaterial( "debug/env_cubemap_model" )
	-- ply:SetMaterial( "models/shadertest/shader5" )

	self:PlayerSetup( ply )
end

function GM:PlayerSetup( ply )
	-- Init health
	ply:SetMaxHealth( PRK_Health )
	ply:SetHealth( PRK_Health )

	-- Init money
	ply:SetNWInt( "PRK_Money", 0 )
    -- Init money fractional value (for multiplier purposes)
    ply:SetNWFloat( "PRK_MoneyFract", 0.0 )

	-- Init gun
	ply:StripWeapons()
	local wep = ply:Give( "prk_gun", true )
	wep:Initialize()

	-- Init speed
	ply:SetCanWalk( false )
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
    PRK_Buff_Register( ply )

	-- Store spawn time
	ply.SpawnTime = CurTime()
	SendSpawn( ply, ply.SpawnTime )

	-- Init collisions
	ply:SetNoCollideWithTeammates( true )
	ply:SetTeam( 1 )

	-- Add head collider
	
end

function GM:Think()
	
end

-- function GM:PlayerDeathThink( ply )
	-- return !ply.PRK_Editor
-- end

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
	if ( target:IsPlayer() and target:Alive() ) then
		if ( !target:IsPlayer() and !string.find( dmginfo:GetInflictor():GetClass(), "prk" ) ) then
			dmginfo:ScaleDamage( 0.2 )
		end
		if ( dmginfo:GetDamageType() == DMG_CRUSH or dmginfo:GetDamageType() == DMG_FALL ) then
			dmginfo:ScaleDamage( 0 )
		end

		if ( dmginfo:GetDamage() > 0 ) then
			local dir = dmginfo:GetInflictor():GetPos() - target:GetPos()
				dir:Normalize()
			SendTakeDamage( target, dmginfo:GetDamage(), dir, dmginfo:GetInflictor():GetPos() )

			-- Play sound
			local pitchhealth = 1 - ( target:Health() / target:GetMaxHealth() )
			PRK_EmitChainPitchedSound(
				target:Nick() .. "_PRK_Hurt",
				target,
				dmgnoises[math.random( 1, #dmgnoises )],
				75,
				0.5 + ( 0.25 / 2 * dmginfo:GetDamage() ),
				math.random( 230, 255 ),
				- ( math.random( 30, 50 ) * pitchhealth ) + 0 * dmginfo:GetDamage(),
				nil,
				1
			)
		end
	end
end

function GM:DoPlayerDeath( ply, attacker, dmginfo )
	local killname = attacker.KillName
		if ( killname == "OWNER" ) then
			attacker = attacker.Owner
		end
		if ( attacker:IsPlayer() ) then
			killname = attacker:Nick()
		elseif ( attacker.KillName ) then
			killname = attacker.KillName
		end
		if ( !killname ) then
			killname = attacker:GetClass()
		end
	SendDie( ply, ply:EyePos(), ply:EyeAngles(), killname )
	ply:SetPos( ply:EyePos() )
end

function GM:PlayerDeathSound()
	return true
end

function GM:OnNPCKilled( npc, attacker, inflictor )
	-- Testing / fun (only non-prickly NPCs)
	if ( string.find( npc:GetClass(), "prk_" ) ) then return end
	local coins = npc:GetMaxHealth() * PRK_Enemy_CoinDropMult
	self:SpawnCoins( npc:GetPos(), coins )
end
-------------------------
  -- /Gamemode Hooks --
-------------------------

function GM:SpawnCoins( pos, coins )
	-- Spawn upwards of position, to avoid falling through floor
	local pos = pos + Vector( 0, 0, 10 )
	local r = math.min( 32, 4 * coins )
	local points = PRK_GetCirclePoints( 0, 0, r, coins, math.random( 0, 360 ) )
	for i = 1, coins do
		PRK_CreateEnt( "prk_coin_heavy", nil, pos + Vector( points[i].x, points[i].y, math.random( -5, 5 ) ), AngleRand(), true )
	end
end

function GM:GenerateLobby()
	local size = PRK_Plate_Size
	local hsize = size / 2

	local origin = Vector( 0, 0, -12289 )
	local amount = 2

	-- Add floor
	local origin = origin + Vector( 0, 0, -hsize * 8 )
	local function createfloor( x, y )
		local floor = PRK_CreateEnt(
			"prk_floor",
			"models/hunter/plates/plate8x8.mdl",
			origin + Vector( size * 8 * y, size * 8 * x, hsize * 8 ),
			Angle( 0, 0, 0 ),
			true,
			true
		)
			floor.Size = { 8 * size, 8 * size }
			floor:DrawShadow( false )
			floor:SetMaterial( "models/rendertarget" )
			floor:SetColor( 0, 0, 0, 255 )
		floor:Spawn()
		floor:SetZone( 0 )
	end
	for x = -amount, amount do
		for y = -amount, amount do
			createfloor( x, y, 0 )
		end
	end

	-- Add walls
	local origin = origin - Vector( 0, 0, -hsize * 8 )
	local function createwall( x, y, yaw )
		local wall = PRK_CreateEnt(
			"prk_wall",
			"models/hunter/plates/plate8x8.mdl",
			origin + Vector( size * 8 * y, size * 8 * x, hsize * 8 ),
			Angle( 90, yaw, 0 ),
			true,
			true
		)
			wall.Size = { 8 * size * ( amount * 2 + 1 ), 0 }
		wall:Spawn()
		wall:SetZone( 0 )
	end
	for x = -1, 1, 2 do
		local y = x * amount * 1
		createwall( 0, y, 0 )
	end
	for y = -1, 1, 2 do
		local x = y * amount * 1
		createwall( x, 0, 90 )
	end

	-- Add ceilings
	local origin = origin + Vector( 0, 0, -hsize * 8 + size * 8 )
	local function createceil( pos, w, h )
		local ceil = PRK_CreateEnt(
			"prk_ceiling",
			"models/hunter/plates/plate8x8.mdl",
			pos,
			Angle( 0, 0, 0 ),
			true,
			true
		)
			ceil:DrawShadow( false )
			ceil:SetNoDraw( true )
			ceil.Size = { w, h }
		ceil:Spawn()
		ceil:SetZone( 0 )
	end
	-- Lobby
	createceil( origin + Vector( 0, 0, hsize * 8 ), 8 * size * amount * 2, 8 * size * amount * 2 )
	-- Play zones
	local flatsize = 15345 * 2
	createceil( Vector( 0, 0, -12800 ) + Vector( 0, 0, size * 8 ), flatsize, flatsize )

	timer.Simple( PRK_Floor_Delete_Time * 1.2, function()
		-- Update any players already in this zone (primarily for server host in lobby)
		for k, ply in pairs( player.GetAll() ) do
			if ( ply:GetNWInt( "PRK_Zone" ) == 0 ) then
				PRK_Floor_MoveToZone( ply, 0 )
			end
		end
	end )
end

function PRK_Explosion( attacker, pos, radius )
	-- Hurt players/push objects
	for k, v in pairs( ents.FindInSphere( pos, radius ) ) do
		if ( v:IsPlayer() or v:IsNPC() or string.find( v:GetClass(), "prk_" ) ) then
			v:TakeDamage( 2, attacker )
		end
		if ( !v:IsPlayer() ) then
			local phys = v:GetPhysicsObject()
			if ( phys and phys:IsValid() ) then
				local dir = ( v:GetPos() - pos ):GetNormalized()
				phys:ApplyForceCenter( dir * 20000 )
			end
		end
	end

	-- Play sound
	-- sound.Play( "ambient/explosions/explode_1.wav", pos, 95, 150, 1 )
	sound.Play( "ambient/explosions/explode_4.wav", pos, 95, 255, 1 )

	-- Show explosion sphere
	local col = PRK_Colour_Explosion
	local time = 0.1
	local rad = 0.9
	for i = 1, 2 do
		local radius_visual = radius * rad
		local sphere = PRK_CreateEnt(
			"prk_debris",
			"models/hunter/misc/shell2x2.mdl",
			pos,
			Angle( 0, 0, 0 )
		)
			sphere:SetMaterial( "models/debug/debugwhite", true )
			sphere:SetColor( col )
			sphere:SetModelScale( radius_visual / PRK_Plate_Size, 0 )
			sphere:SetModelScale( 0, time )
			sphere:SetNWBool( "Explosion", true )
		timer.Simple( time, function()
			if ( sphere and sphere:IsValid() ) then
				sphere:Remove()
			end
		end )
		col = Color( 0, 0, 0, 255 )
		time = time + 0.1
		rad = rad - 0.4
	end

	-- Play particle effect
	
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
-- Class (String), Model (String), Position (Vector), Angle (Angle), Should Move? (bool), Should auto spawn? (bool)
function PRK_CreateEnt( class, mod, pos, ang, mov, nospawn )
	local ent = ents.Create( class )
		if ( mod ) then
			ent:SetModel( mod )
		end
		ent:SetPos( pos )
		ent:SetAngles( ang )
		if ( !nospawn ) then
			ent:Spawn()
		end
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
