--
-- Prickly Summer 2018
-- 03/06/18
--
-- Main Shared
--

GM.Name = "Prickly Summer 2018"
GM.Author = "johnjoemcbob & DrMelon"
GM.Email = ""
GM.Website = "https://github.com/johnjoemcbob/GMod-Summer-2018"

PRK_SANDBOX = true
if PRK_SANDBOX then
DeriveGamemode( "Sandbox" ) -- For testing purposes, nice to have spawn menu etc
else
DeriveGamemode( "base" )
end

-----------------
  -- Globals --
-----------------
-- HUD
PRK_HUD_Shadow_DistX							= -2
PRK_HUD_Shadow_DistY							= 2
PRK_HUD_Shadow_Effect							= 4
PRK_HUD_Punch_Amount							= 5
PRK_HUD_Punch_Speed								= 10
PRK_HUD_DieEffect_MaxAlpha						= 230

-- Colours
PRK_HUD_Colour_Main								= Color( 255, 255, 255, 255 )
PRK_HUD_Colour_Dark								= Color( 0, 0, 0, 255 )
PRK_HUD_Colour_Money							= Color( 255, 255, 50, 255 )
PRK_HUD_Colour_Shadow							= Color( 255, 100, 150, 255 )
PRK_HUD_Colour_Highlight						= Color( 100, 190, 190, 255 )
PRK_HUD_Colour_Heart_Dark						= Color( 70, 20, 30, 255 )
PRK_HUD_Colour_Heart_Light						= Color( 150, 20, 70, 255 )

PRK_Colour_Player								= {
													Color( 255, 100, 150, 255 ),
													Color( 253, 203, 110, 255 ),
													Color( 0, 206, 201, 255 ),
													Color( 85, 239, 196, 255 ),
													Color( 162, 155, 254, 255 ),
													Color( 255, 118, 117, 255 ),
													Color( 89, 98, 117, 255 ),
}

PRK_Colour_Enemy_Skin							= Color( 0, 0, 5, 255 )
PRK_Colour_Enemy_Eye							= PRK_HUD_Colour_Shadow
PRK_Colour_Enemy_Tooth							= PRK_HUD_Colour_Main
PRK_Colour_Enemy_Mouth							= Color( 100, 100, 100, 255 )
PRK_Colour_Explosion							= Color( 255, 150, 0, 255 )

-- Grass
PRK_Grass_Colour								= Color( 40, 40, 40, 255 )
PRK_Grass_Mesh									= true
-- PRK_Grass_Mesh									= false -- FPS test
PRK_Grass_Mesh_CountRange						= { 0.1, 0.2 }
-- PRK_Grass_Mesh_CountRange						= { 0, 0 } -- FPS test
PRK_Grass_Mesh_Disruption						= true
-- PRK_Grass_Mesh_Disruption						= false -- FPS test
PRK_Grass_Mesh_DisruptTime						= 0.2
PRK_Grass_Mesh_DisruptorInnerRange				= 50
PRK_Grass_Mesh_DisruptorOuterRange				= 4000
PRK_Grass_Mesh_Disruptors						= {
													"player",
													"prk_bullet_heavy",
													"prk_laser_heavy",
													"prk_coin_heavy",
													"prk_npc_biter",
													"prk_npc_sploder",
													"prk_debris",
													"prk_gateway",
													"prk_potion",
}
PRK_Grass_Billboard								= true
-- PRK_Grass_Billboard								= false -- FPS test
PRK_Grass_Billboard_Count						= 3
PRK_Grass_Billboard_DrawRange					= 5000
PRK_Grass_Billboard_Forward						= 200 --400
PRK_Grass_Billboard_ShouldDrawTime				= 0.1
PRK_Grass_Billboard_MaxRenderCount				= 1000
PRK_Grass_Billboard_MultipleSprite				= false

PRK_Wall_Detail_Mesh_Count						= function()
													return math.max( 0, math.random( -10, 1 ) )
													-- return 0
												end

PRK_Decal										= true
-- PRK_Decal										= false -- FPS test
PRK_Decal_Max									= 200
PRK_Decal_CombineDist							= 10

-- Visuals
PRK_Epsilon										= 0.001
PRK_Plate_Size									= 47.45
PRK_DrawMap										= false
PRK_DrawDistance								= 4000
PRK_MaxAverageFrameTimes						= 10
PRK_CurrencyBefore								= "€"
PRK_CurrencyAfter								= ""
PRK_CursorSize									= 6

-- Gateway
PRK_Gateway_StartOpenRange						= 500
PRK_Gateway_MaxScale							= 5
PRK_Gateway_PullRange							= 300
PRK_Gateway_PullForce							= 100
PRK_Gateway_EnterRange							= 100
PRK_Gateway_OpenSpeed							= 5
PRK_Gateway_TravelTime							= 5
PRK_Gateway_FlashHoldTime						= 0.2
PRK_Gateway_FlashSpeed							= 10
PRK_Gateway_FOVSpeedEnter						= 0.5
PRK_Gateway_FOVSpeedExit						= 5
PRK_Gateway_ParticleDelay						= 0.05
PRK_Gateway_ParticleDelayTravel					= 0.1 --0.05
PRK_Gateway_Segments							= 48

-- Editor
PRK_Editor_MoveSpeed							= 2
PRK_Editor_Zoom_Step							= 30
PRK_Editor_Zoom_Speed							= 10
PRK_Editor_Zoom_Min								= 50
PRK_Editor_Zoom_Default							= 500
PRK_Editor_Zoom_Max								= 2000
PRK_Editor_Grid_Scale							= 0.5
PRK_Editor_Grid_Size							= 1024
PRK_Editor_Square_Size							= PRK_Plate_Size
PRK_Editor_Square_Border_Min					= 8
PRK_Editor_Square_Border_Add					= 4

-- Level Generation
PRK_Gen_Seed									= 2
PRK_Gen_SizeModifier							= 3 -- 6 -- 7 -- 5 --0.01 -- 10
PRK_Gen_DetailWaitTime							= 1
PRK_Gen_StepBetweenTime							= 0.1 --0--5
PRK_Gen_FloorDeleteTime							= ( PRK_Gen_StepBetweenTime * 4 ) + 5 -- Gotta wait around long enough to collide
PRK_Gen_IgnoreEnts								= { false, false, true, false }
PRK_Gen_WallCollide								= false

-- Damage/Death
PRK_Hurt_Material								= "pp/texturize/pattern1.png"
PRK_Hurt_ShowTime								= 0.2
PRK_Death_Material								= "pp/texturize/plain.png"
PRK_Death_Sound									= "music/stingers/hl1_stinger_song27.mp3"

-- Enemy
PRK_Enemy_PhysScale								= 2
PRK_Enemy_Scale									= 2 -- 3
PRK_Enemy_Speed									= 300 -- 500
PRK_Enemy_Types									= {
													["Biter"] = "prk_npc_biter",
													["Sploder"] = "prk_npc_sploder",
													["Turret"] = "prk_turret_heavy",
}
PRK_Enemy_CoinDropMult							= 0.2 -- 0.1

-- Player
PRK_BaseClip									= 3 --6
PRK_Health										= 6
PRK_Speed										= 600
PRK_Jump										= 0

-- Gun
PRK_Gun_PunchLerpSpeed							= 1
PRK_Gun_MoveLerpSpeed							= 30
PRK_Gun_HUDLerpSpeed							= 5
PRK_Gun_HUDScaleMultiplier						= 8

-- Misc
PRK_Height_OutOfWorld							= -10000000000 -- -12735
PRK_Position_Nowhere							= Vector( 0, 0, -20000 )
PRK_DataPath									= "prickly/"

function GM:FlatgrassZones()
	local y = -12800

	-- Ignore lobby in middle of flatgrass
	local lobbymin = Vector( -1000, -1000, y )
	local lobbymax = Vector( 1000, 1000, y )

	-- 3 divisions of width/breadth
	local div = 3

	-- Map bounds
	local min = Vector( -15345, -15345, y )
	local max = Vector( 15345, 15345, y )

	-- Get zone size
	local width = ( max.x - lobbymax.x )
	local breadth = ( max.y - lobbymax.y )

	-- Generate and store zones
	local zones = {}
		for w = 0, 1 do
			for b = 0, 1 do
				local pos = Vector( min.x, min.y, min.z )
					if ( w == 0 ) then
						pos.x = min.x + width / 2
					else
						pos.x = max.x - width / 2
					end
					if ( b == 0 ) then
						pos.y = min.y + width / 2
					else
						pos.y = max.y - width / 2
					end
				table.insert( zones, {
					pos = pos,
					width = width,
					breadth = breadth,
				} )
			end
		end

		-- Debug draw
		for k, zone in pairs( zones ) do
			debugoverlay.Box(
				zone.pos,
				Vector( -width / 2, -breadth / 2, 0 ),
				Vector( width / 2, breadth / 2, 10 ),
				30,
				ColorRand()
			)
		end
	return zones
end

function GM:BasicGridZones()
	-- 3 divisions of width/breadth
	local div = 3

	-- Map bounds
	local min = Vector( -15345, -15345, -12735 )
	local max = Vector( 15345, 15345, -12735 )

	-- Get total map size
	local width = math.abs( min.x ) + math.abs( max.x )
	local breadth = math.abs( min.y ) + math.abs( max.y )

	-- Get zone size
	width = width / div
	breadth = breadth / div

	-- Generate and store zones
	local zones = {}
		for w = 1, div do
			for b = 1, div do
				table.insert( zones, {
					pos = min + Vector( width * ( w - 0.5 ), breadth * ( b - 0.5 ), 0 ),
					width = width,
					breadth = breadth,
				} )
			end
		end

		-- Debug draw
		for k, zone in pairs( zones ) do
			debugoverlay.Box(
				zone.pos,
				Vector( -width / 2, -breadth / 2, 0 ),
				Vector( width / 2, breadth / 2, 10 * ( w + b ) ),
				30,
				ColorRand()
			)
		end
	return zones
end

------------------------
  -- Gamemode Hooks --
------------------------
function GM:PlayerFootstep( ply, pos, foot, sound, volume, rf )
	ply:EmitSound(
		"player/footsteps/gravel" .. math.random( 1, 4 ) .. ".wav",
		75,
		math.Clamp( ( math.random( 90, 120 ) * ply:GetVelocity() / 600 ):Length(), 0, 255 ),
		volume
	)

	-- Grass effect
	local effectdata = EffectData()
		local pos = pos
		effectdata:SetOrigin( pos )
		effectdata:SetNormal( Vector( 0, 0, 1 ) )
	util.Effect( "prk_grass", effectdata )

	-- Dust effect
	local effectdata = EffectData()
		local pos = pos
		effectdata:SetOrigin( pos )
		effectdata:SetNormal( Vector( 0, 0, 1 ) )
	util.Effect( "prk_hit", effectdata )

	return true
end
------------------------
  -- /Gamemode Hooks --
------------------------

local meta_ply = FindMetaTable( "Player" )
function meta_ply:JustSpawned()
	return ( self.SpawnTime and ( CurTime() - self.SpawnTime ) < 0.4 )
end

-- Average the frametime over a few frames to stop viewmodel jittering when lerping
PRK_AverageFrameTimes = {}
PRK_AverageFrameTime = 0
hook.Add( "Think", "PRK_Think_FrameTime", function()
	table.insert( PRK_AverageFrameTimes, FrameTime() )
		if ( #PRK_AverageFrameTimes > PRK_MaxAverageFrameTimes ) then
			table.remove( PRK_AverageFrameTimes, 1 )
		end
		for k, frametime in pairs( PRK_AverageFrameTimes ) do
			PRK_AverageFrameTime = PRK_AverageFrameTime + frametime
		end
	PRK_AverageFrameTime = PRK_AverageFrameTime / PRK_MaxAverageFrameTimes
end )

function PRK_GetFrameTime()
	-- if ( CLIENT ) then
		-- return RealFrameTime()
	-- end
	-- return FrameTime()
	if ( !PRK_AverageFrameTime or PRK_AverageFrameTime == 0 ) then
		return 0.016
	end
	return PRK_AverageFrameTime -- FrameTime() -- 0.016
end

-- Sounds with pitch asc/desc when played in a row
PRK_ChainPitchedSounds = {}
hook.Add( "Think", "PRK_Think_PitchSounds", function()
	for name, pitch in pairs( PRK_ChainPitchedSounds ) do
		-- pitch.Current = Lerp( FrameTime() * pitch.Speed, pitch.Current, pitch.Default )
		-- pitch.Current = math.Approach( pitch.Current, pitch.Default, FrameTime() * pitch.Speed )

		-- Works better based on time rather than old pitch attempt (shown above)
		if ( pitch.Time_End <= CurTime() ) then
			pitch.Current = pitch.Default
			pitch.Chain = 0
			if ( pitch.Callback_End ) then
				pitch:Callback_End()
				pitch.Callback_End = nil
			end
		end
	end
end )

function PRK_EmitChainPitchedSound( name, ent, sound, level, vol, pitchdefault, pitchchange, pitchspeed, time_end, callback_end, chain_add )
	-- Initialise
	if ( !PRK_ChainPitchedSounds[name] ) then
		PRK_ChainPitchedSounds[name] = {
			Current = pitchdefault,
			Chain = 0,
		}
	end
	-- Update any values
	PRK_ChainPitchedSounds[name].Default = pitchdefault
	PRK_ChainPitchedSounds[name].Change = pitchchange
	PRK_ChainPitchedSounds[name].Speed = pitchspeed
	PRK_ChainPitchedSounds[name].Time_End = CurTime() + ( time_end or 1000 )
	PRK_ChainPitchedSounds[name].Callback_End = callback_end

	-- Apply change
	PRK_ChainPitchedSounds[name].Current = math.Clamp( PRK_ChainPitchedSounds[name].Current + pitchchange, 0, 255 )
	PRK_ChainPitchedSounds[name].Chain = PRK_ChainPitchedSounds[name].Chain + (chain_add or 1)

	-- Play audio
	ent:EmitSound( sound, level, PRK_ChainPitchedSounds[name].Current, vol )

	return PRK_ChainPitchedSounds[name].Chain
end

function PRK_GetAsCurrency( val )
	return PRK_CurrencyBefore .. tostring( val ) .. PRK_CurrencyAfter
end

function PRK_InEditor( ply )
	return ( ply.PRK_Editor or ply.PRK_Editor_Room )
end

-- Easier for testing than writing out the whole function each time
-- Requires "developer 1" in console
function PRK_BasicDebugSphere( pos )
	debugoverlay.Sphere(
		pos,
		5,
		10,
		Color( 255, 255, 255, 255 ),
		true
	)
end

-- From: http://wiki.garrysmod.com/page/surface/DrawPoly
function PRK_GetCirclePoints( x, y, radius, seg, rotate )
	local cir = {}
		-- table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
		for i = 0, seg do
			local a = math.rad( ( ( i / seg ) * -360 ) + rotate )
			table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
		end

		-- local a = math.rad( 0 ) -- This is need for non absolute segment counts
		-- table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
	return cir
end

function ColourToVector( col, range )
	if ( range == nil ) then range = 1 end

	local vector = Vector()
		vector.x = col.r / 255 * range
		vector.y = col.g / 255 * range
		vector.z = col.b / 255 * range
	return vector
end

function VectorToColour( vector, range )
	if ( range == nil ) then range = 1 end

	local col = Color( 255, 255, 255, 255 )
		col.r = vector.x / range * 255
		col.g = vector.y / range * 255
		col.b = vector.z / range * 255
		col.a = 255
	return col
end

function math.Wrap( cur, min, max )
	local ret = tonumber( cur )
		if ( ret < min ) then
			ret = max
		end
		if ( ret > max ) then
			ret = min
		end
	return ret
end

-- Make a shallow copy of a table (from http://lua-users.org/wiki/CopyTable)
-- Extended for recursive tables
function table.shallowcopy( orig )
    local orig_type = type( orig )
    local copy
    if ( orig_type == "table" ) then
        copy = {}
        for orig_key, orig_value in pairs( orig ) do
			if ( type( orig_value ) == "table" ) then
				copy[orig_key] = table.shallowcopy( orig_value )
			else
				copy[orig_key] = orig_value
			end
        end
	-- Number, string, boolean, etc
    else
        copy = orig
    end
    return copy
end

-- Get length of table
-- Works with string keys, # only works with integer indices
function table.length(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

function math.approx( num, target )
	local dif = math.abs( num - target )
	return dif < PRK_Epsilon
end

function LerpAngleBasic( t, from, to )
	local ret = from
		ret.p = Lerp( t, from.p, to.p )
		ret.y = Lerp( t, from.y, to.y )
		ret.r = Lerp( t, from.r, to.r )
	return ret
end

-- Negate a Vector without having 0 -> -0 issues
function VectorNegate( V )
	local ret = -V
		if ( ret.x == -0 ) then
			ret.x = 0
		end
		if ( ret.y == -0 ) then
			ret.y = 0
		end
		if ( ret.z == -0 ) then
			ret.z = 0
		end
	return ret
end

function VectorRound( V )
	return Vector(
		math.Round( V.x ),
		math.Round( V.y ),
		math.Round( V.z )
	)
end

function VectorAbs( V )
	return Vector(
		math.abs( V.x ),
		math.abs( V.y ),
		math.abs( V.z )
	)
end

function VectorIsZero( V )
	return (
		( V.x == 0 or V.x == -0 ) and
		( V.y == 0 or V.y == -0 ) and
		( V.z == 0 or V.z == -0 )
	)
end

function VectorIsApproximatelyZero( V )
	local dec = 3
	V.x = math.Round( V.x, dec )
	V.y = math.Round( V.y, dec )
	V.z = math.Round( V.z, dec )
	return VectorIsZero( V )
end

-- https://codereview.stackexchange.com/questions/98787/checking-if-the-point-is-on-the-line-segment
function intersect_point_line( c, a, b )
	local crossproduct = (c.y - a.y) * (b.x - a.x) - (c.x - a.x) * (b.y - a.y)

	-- compare versus epsilon for floating point values, or != 0 if using integers
	if math.abs(crossproduct) > PRK_Epsilon then
		return false
	end

	local dotproduct = (c.x - a.x) * (b.x - a.x) + (c.y - a.y) * (b.y - a.y)
	if dotproduct < 0 then
		return false
	end

	local squaredlengthba = (b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y)
	if dotproduct > squaredlengthba then
		return false
	end

	return true
end

-- http://stackoverflow.com/a/23976134/1190664
-- ray.position is a vector
-- ray.direction is a vector
-- plane.position is a vector
-- plane.normal is a vector
function intersect_ray_plane( ray, plane )
	local denom = plane.normal:Dot( ray.direction )

	-- Ray does not intersect plane
	if math.abs( denom ) < PRK_Epsilon then
		return false
	end

	-- Distance of direction
	local d = plane.position - ray.position
	local t = d:Dot( plane.normal ) / denom

	if t < PRK_Epsilon then
		return false
	end

	-- Return collision point and distance from ray origin
	return ray.position + ray.direction * t, t
end

-- point is a vector
-- square is a table
function intersect_point_square( point, square )
	local min = Vector( math.min( square.x[1], square.x[2] ), math.min( square.y[1], square.y[2] ), 0 )
	local max = Vector( math.max( square.x[1], square.x[2] ), math.max( square.y[1], square.y[2] ), 0 )
	return (
		point.x >= min.x and
		point.x <= max.x and
		point.y >= min.y and
		point.y <= max.y
	)
end

-- From: https://gamedev.stackexchange.com/questions/29786/a-simple-2d-rectangle-collision-algorithm-that-also-determines-which-sides-that
-- a is a table
-- b is a table
function intersect_squares( a, b )
	local a_min = Vector( math.min( a.x[1], a.x[2] ), math.min( a.y[1], a.y[2] ), 0 )
	local a_max = Vector( math.max( a.x[1], a.x[2] ), math.max( a.y[1], a.y[2] ), 0 )
	local b_min = Vector( math.min( b.x[1], b.x[2] ), math.min( b.y[1], b.y[2] ), 0 )
	local b_max = Vector( math.max( b.x[1], b.x[2] ), math.max( b.y[1], b.y[2] ), 0 )

	local a_width = a_max.x - a_min.x
	local a_height = a_max.y - a_min.y
	local b_width = b_max.x - b_min.x
	local b_height = b_max.y - b_min.y

	local a_center = a_min + ( a_max - a_min ) / 2
	local b_center = b_min + ( b_max - b_min ) / 2

	local w = 0.5 * ( a_width + b_width )
	local h = 0.5 * ( a_height + b_height )
	local dx = a_center.x - b_center.x
	local dy = a_center.y - b_center.y

	return ( math.abs( dx ) <= w and math.abs( dy ) <= h )
end
