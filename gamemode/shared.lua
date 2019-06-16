--
-- Prickly Summer 2018
-- 03/06/18
--
-- Main Shared
--

-- LUA Downloads
if ( SERVER ) then
AddCSLuaFile( "sh_globals.lua" )
AddCSLuaFile( "sh_items.lua" )
end

-- Only allow global include here
include( "sh_globals.lua" )

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
					pos = pos + Vector( width / 2, 0, 0 ), -- Offset since entry always faces same direction
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

function PRK_ResizePhysics( ent, scale )
	-- Parameter can be a float instead of Vector if all axes should be same scale
	if ( scale == tonumber( scale ) ) then
		scale = Vector( 1, 1, 1 ) * scale
	end

	ent:PhysicsInit( SOLID_VPHYSICS )

	local phys = ent:GetPhysicsObject()
	if ( phys and phys:IsValid() ) then
		local physmesh = phys:GetMeshConvexes()
			if ( not istable( physmesh ) ) or ( #physmesh < 1 ) then return end

			for convexkey, convex in pairs( physmesh ) do
				for poskey, postab in pairs( convex ) do
					local pos = postab.pos
						pos.x = pos.x * scale.x
						pos.y = pos.y * scale.y
						pos.z = pos.z * scale.z
					convex[ poskey ] = pos
				end
			end
		ent:PhysicsInitMultiConvex( physmesh )

		ent:EnableCustomCollisions( true )
	end

	local phys = ent:GetPhysicsObject()
	if ( phys and phys:IsValid() ) then
		phys:EnableMotion( false )
	end
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
	PRK_ChainPitchedSounds[name].Current = math.Clamp( PRK_ChainPitchedSounds[name].Current + pitchchange, 10, 255 )
	PRK_ChainPitchedSounds[name].Chain = PRK_ChainPitchedSounds[name].Chain + (chain_add or 1)

	-- Play audio
	ent:EmitSound( sound, level, PRK_ChainPitchedSounds[name].Current, vol )

	return PRK_ChainPitchedSounds[name].Chain
end

function PRK_GetAsCurrency( val )
	local neg = ""
		if ( val < 0 ) then
			val = math.abs( val )
			neg = "-"
		end
	return neg .. PRK_CurrencyBefore .. tostring( val ) .. PRK_CurrencyAfter
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

-- For non-sequential tables (table.Random didn't work properly?)
function TableRandom( tab )
	local keys = {}
		for k, v in pairs( tab ) do
			table.insert( keys, k )
		end
	local key = keys[math.random( 1, #keys )]
	return tab[key], key
end

function LerpColour( dif, current, target )
	return Color(
		Lerp( dif, current.r, target.r ),
		Lerp( dif, current.g, target.g ),
		Lerp( dif, current.b, target.b ),
		Lerp( dif, current.a, target.a )
	)
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

function math.sign( num )
	if ( num < 0 ) then
		return -1
	else
		return 1
	end
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
