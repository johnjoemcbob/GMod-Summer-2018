--
-- Prickly Summer 2018
-- 03/06/18
--
-- Main Serverside
--

-- LUA Downloads
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_editor_room.lua" )
AddCSLuaFile( "cl_modelcache.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "lua/includes/modules/3d2dvgui.lua" )

-- LUA Includes
include( "shared.lua" ) -- Must be first for globals
include( "sh_items.lua" )
include( "levelgen.lua" )
include( "buffs.lua" )

-- Resource Downloads
local dir = PRK_GamemodePath .. "content/"
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
-- resource.AddWorkshop( "1468209847" )
print( "Finish resources..." )
print( "-------------------" )

-- Net
util.AddNetworkString( "PRK_KeyValue" )
util.AddNetworkString( "PRK_TakeDamage" )
util.AddNetworkString( "PRK_Blood" )
util.AddNetworkString( "PRK_Die" )
util.AddNetworkString( "PRK_Drink" )
util.AddNetworkString( "PRK_Spawn" )
util.AddNetworkString( "PRK_ResetZone" )
util.AddNetworkString( "PRK_Editor" )
util.AddNetworkString( "PRK_EditorExport" )

function PRK_SendKeyValue( ply, key, val )
	net.Start( "PRK_KeyValue" )
		net.WriteString( key )
		net.WriteString( val )
	net.Send( ply )
end

function PRK_SendTakeDamage( ply, amount, dir, pos )
	net.Start( "PRK_TakeDamage" )
		net.WriteEntity( ply )
		net.WriteFloat( amount )
		net.WriteVector( dir )
		net.WriteVector( pos )
	net.Broadcast()
end

function PRK_SendBlood( pos, dir, col )
	net.Start( "PRK_Blood" )
		net.WriteVector( pos )
		net.WriteVector( dir )
		net.WriteColor( col )
	net.Broadcast()
end

function PRK_SendDie( ply, pos, ang, killname )
	net.Start( "PRK_Die" )
		net.WriteEntity( ply )
		net.WriteVector( pos )
		net.WriteAngle( ang )
		net.WriteString( killname )
	net.Broadcast()
end

function PRK_SendDrink( ply )
	net.Start( "PRK_Drink" )
		net.WriteEntity( ply )
	net.Broadcast()
end

function PRK_SendSpawn( ply, time )
	net.Start( "PRK_Spawn" )
		net.WriteFloat( time )
	net.Send( ply )
end

function PRK_SendResetZone( zone )
	net.Start( "PRK_ResetZone" )
		net.WriteFloat( zone )
	net.Broadcast()
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
	-- Force flatgrass
	if ( game.GetMap() != "gm_flatgrass" ) then
		local msg = "WRONG MAP - SWITCHING"
		print( msg )
		PrintMessage( HUD_PRINTCENTER, msg )
		RunConsoleCommand( "changelevel", "gm_flatgrass" )
		return
	end

	-- Hide sun
	local suns = ents.FindByClass( "env_sun" )
	for k, sun in pairs( suns ) do
		sun:SetKeyValue( "size", 0 )
		sun:SetKeyValue( "overlaysize", 0 )
	end

	-- Generate and connect world
	math.randomseed( 0 )
		self:GenerateLobby()
	math.randomseed( os.time() )

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
	local function gen( zone )
		-- Create gateway to link to this
		local ent = PRK_CreateEnt( "prk_gateway", nil, gates[zone][1], gates[zone][2] )
		ent:SetDestination( PRK_Zones[zone].pos, zone )
		ent:SetZone( 0 )
		PRK_Destination_LevelStartTemp = PRK_Zones[zone].pos -- Temp and bad but there are only a few hours left :)
	end

	PRK_Zones = self:FlatgrassZones()
	-- local function verytest()
		-- gen( 1 )
		-- timer.Simple( 20, function()
			-- verytest()
		-- end )
	-- end
	-- verytest()
	timer.Simple( 5, function()
		gen( 1 )
		self:GenerateNextFloor( 1 )
	end )
end

function GM:GenerateNextFloor( zone )
	self.Floors = ( self.Floors or 0 ) + 1
	print( "Floor: " .. self.Floors )

	-- Temp for judging so I know what's coming :)
	if ( PRK_Gen_Seed != nil ) then
		math.randomseed( PRK_Gen_Seed + self.Floors )
	end

	-- Clear any remaining entities with this zone
	-- (other than the gateway currently trasporting the players!)
	PRK_SendResetZone( zone )
	PRK_Floor_ResetZone( zone )
	PRK_Gen_Remove()
	for k, v in pairs( ents.GetAll() ) do
		if ( v and v:IsValid() and v.Zone and v.Zone == zone and v:GetClass() != "prk_gateway" ) then
			v.Cleanup = true
			v:Remove()
		end
	end

	-- Generate new
	PRK_Gen( PRK_Zones[zone].pos, zone )

	-- Update any players already in this zone (primarily for dev test)
	timer.Simple( PRK_Gen_FloorDeleteTime * 1.2, function()
		for k, ply in pairs( player.GetAll() ) do
			if ( ply:GetNWInt( "PRK_Zone" ) == zone ) then
				PRK_Floor_MoveToZone( ply, zone )
			end
		end
	end )
end

-- Requires sv_cheats 1 sadly
function GM:PlayerInitialSpawn( ply )
	ply:ConCommand( "mat_fullbright 1" )
end

function GM:PlayerDisconnected( ply )
	ply:ConCommand( "mat_fullbright 0" )
end

function GM:MoveToZone( ply, zone )
	local oldzone = ply:GetNWInt( "PRK_Zone", 0 )

	ply:SetNWInt( "PRK_Zone", zone )

	-- Floors
	PRK_Floor_MoveToZone( ply, zone )

	-- Reset player info if coming travelling to/from the lobby
	if ( oldzone == 0 or zone == 0 ) then
		self:PlayerSetup( ply )
	end

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

	-- Position centrally
	ply:SetPos( Vector( 0, 0, ply:GetPos().z ) )

	-- Fix weird view punch issue, and give nice spawn effect
	ply:SetFOV( 0, 0 )
	ply:ViewPunch( Angle( -50, 0, 0 ) )

	-- Player model/colour
	ply:SetModel( "models/player/soldier_stripped.mdl" )
	ply:SetMaterial( PRK_Material_Base )
	local cols = PRK_Colour_Player
	ply:SetColor( cols[math.random( 1, #cols )] )

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
	PRK_SendSpawn( ply, ply.SpawnTime )

	-- Init collisions
	ply:SetNoCollideWithTeammates( true )
	ply:SetTeam( 1 )

	-- Add head collider
	
end

function GM:Think()
	-- Handle player input 
	for k, ply in pairs( player.GetAll() ) do
		-- Trace use
		if ( ply:KeyDown( IN_USE ) ) then
			PRK_HandleUse( ply )
		end
	end
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
			PRK_SendTakeDamage( target, dmginfo:GetDamage(), dir, dmginfo:GetInflictor():GetPos() )

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
	-- Send killer name to client
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
		if ( ply.PRK_OverrideDeathMessage ) then
			killname = ply.PRK_OverrideDeathMessage
		end
		-- Pick a random value in case a table of possibilities is provided
		if ( type(killname) == "table" ) then
			killname = killname[math.random( 1, #killname )]
		end
	PRK_SendDie( ply, ply:EyePos(), ply:EyeAngles(), killname )

	-- Smooth transition into falling eyes anim
	ply:SetPos( ply:EyePos() )

	-- Drop old use items
	if ( !ply.PRK_Item_DisableDropOnDeath ) then
		PRK_DropItem( ply )
	end
end

function GM:PlayerDeathSound()
	return true
end

function GM:OnNPCKilled( npc, attacker, inflictor )
	-- Testing / fun (only non-prickly NPCs)
	if ( string.find( npc:GetClass(), "prk_" ) ) then return end
	local coins = npc:GetMaxHealth() * PRK_Enemy_CoinDropMult
	self:SpawnCoins( npc, npc:GetPos(), coins )
end
-------------------------
  -- /Gamemode Hooks --
-------------------------

function PRK_HandleUse( ply )
	if ( !ply.PRK_NextUse or ply.PRK_NextUse <= CurTime() ) then
		local tr = util.TraceLine( {
			start = ply:EyePos(),
			endpos = ply:EyePos() + ply:EyeAngles():Forward() * PRK_UseRange,
			filter = { ply },
		} )
		if ( tr.Entity ) then
			if ( tr.Entity.TraceUse ) then
				tr.Entity:TraceUse( ply )
				ply.PRK_NextUse = CurTime() + PRK_UseBetween
			end
		end
	end
end

function PRK_HandleJump( ply, cmd, args )
	PRK_UseItem( ply )
end
concommand.Add( "+prk_jump", PRK_HandleJump )

function PRK_HandleDuck( ply, cmd, args )
	PRK_DropItem( ply )
end
concommand.Add( "+prk_duck", PRK_HandleDuck )

function PRK_OverrideDeathMessage( plytab, message )
	local function set( ply )
		ply.PRK_OverrideDeathMessage = message
	end

	if ( type(plytab) == "table" ) then
		for k, ply in pairs( plytab ) do
			set( ply )
		end
	else
		set( plytab )
	end
end

function GM:SpawnCoins( source, pos, coins )
	-- Spawn upwards of position, to avoid falling through floor
	local pos = pos + Vector( 0, 0, 10 )
	local r = math.min( 32, 4 * coins )
	local points = PRK_GetCirclePoints( 0, 0, r, coins, math.random( 0, 360 ) )
	for i = 1, coins do
		local ent = PRK_CreateEnt( "prk_coin_heavy", nil, pos + Vector( points[i].x, points[i].y, math.random( -5, 5 ) ), AngleRand(), true )
		ent:SetZone( source.Zone )
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
			floor:SetColor( Color(0, 0, 0, 255) )
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
			Angle( 0, 0, 0 ),
			true,
			true
		)
			wall.Size = { 8 * size * ( amount * 2 + 1 ), 0 }
			if ( yaw == 0 ) then
				wall.Size = { 0, 8 * size * ( amount * 2 + 1 ) }
			end
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

	-- Combine walls
	local ent = ents.Create( "prk_wall_combined" )
	ent:Spawn()

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

	-- Add details
	local floor = origin - Vector( 0, 0, hsize * 8 )
	local lobbydetails = {
		-- {
			-- "models/xqm/button3.mdl",
			-- floor,
			-- Angle(),
			-- 10,
			-- PRK_Material_Base,
			-- Color( 100, 190, 190, 255 ),
		-- },
	}
	for k, v in pairs( lobbydetails ) do
		local ent = PRK_CreateEnt(
			"prop_physics",
			v[1],
			v[2],
			v[3]
		)
		ent:SetModelScale( v[4] )
		PRK_ResizePhysics( ent, v[4] )
		ent:SetMaterial( v[5] )
		ent:SetColor( v[6] )
	end

	-- Update any players already in this zone (primarily for server host in lobby)
	timer.Simple( PRK_Gen_FloorDeleteTime * 1.1, function()
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
			sphere:SetMaterial( PRK_Material_Base, true )
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
