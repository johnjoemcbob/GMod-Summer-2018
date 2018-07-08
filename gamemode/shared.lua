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

--DeriveGamemode( "base" )
DeriveGamemode( "Sandbox" ) -- For testing purposes, nice to have spawn menu etc

-- Globals
PRK_HUD_Colour_Main							= Color( 255, 255, 255, 255 )
PRK_HUD_Colour_Dark							= Color( 0, 0, 0, 255 )
PRK_HUD_Colour_Money						= Color( 255, 255, 50, 255 )
PRK_HUD_Colour_Shadow						= Color( 255, 100, 150, 255 )
PRK_HUD_Colour_Highlight					= Color( 100, 190, 190, 255 )
PRK_HUD_Colour_Heart_Dark					= Color( 70, 20, 30, 255 )
PRK_HUD_Colour_Heart_Light					= Color( 150, 20, 70, 255 )
PRK_HUD_Shadow_DistX						= -2
PRK_HUD_Shadow_DistY						= 2
PRK_HUD_Shadow_Effect						= 4
PRK_HUD_Punch_Amount						= 5
PRK_HUD_Punch_Speed							= 10
PRK_HUD_DieEffect_MaxAlpha				= 230
PRK_Colour_Enemy_Skin						= Color( 0, 0, 5, 255 )
PRK_Colour_Enemy_Eye							= PRK_HUD_Colour_Shadow
PRK_Colour_Enemy_Tooth						= PRK_HUD_Colour_Main
PRK_Colour_Enemy_Mouth						= Color( 100, 100, 100, 255 )
PRK_Colour_Explosion							= Color( 255, 150, 0, 255 )
PRK_Grass_Mesh_CountRange				= { 1, 6 } -- { 0, 2 }
PRK_Grass_Billboard_Count					= 100
PRK_Grass_Billboard_DrawRange			= 1000
PRK_Grass_Billboard_SortRange				= 10
PRK_Grass_Billboard_ShouldDrawTime	= 1
PRK_Grass_Billboard_MaxSortCount		= 0
PRK_Grass_Billboard_MaxRenderCount	= 4000
PRK_DrawDistance									= 4000
PRK_Gen_SizeModifier							= 10
PRK_Enemy_CoinDropMult						= 0.2 -- 0.1
PRK_CurrencyBefore								= "€"
PRK_CurrencyAfter									= ""
PRK_CursorSize										= 8
PRK_BaseClip										= 1
PRK_Hurt_Material									= "pp/texturize/pattern1.png"
PRK_Hurt_ShowTime								= 0.2
PRK_Death_Material								= "pp/texturize/plain.png"
PRK_Death_Sound									= "music/stingers/hl1_stinger_song27.mp3"
PRK_Plate_Size										= 47.45
PRK_Health											= 6
PRK_Speed											= 600
PRK_Jump												= 0
PRK_MaxAverageFrameTimes					= 50

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

	-- if ( CLIENT ) then
		local effectdata = EffectData()
			local pos = pos
			effectdata:SetOrigin( pos )
			effectdata:SetNormal( Vector( 0, 0, 1 ) )
		util.Effect( "prk_hit", effectdata )
	-- end

	return true
end
------------------------
  -- /Gamemode Hooks --
------------------------

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
	if ( !PRK_AverageFrameTime or PRK_AverageFrameTime == 0 ) then
		return 0.016
	end
	-- print( PRK_AverageFrameTime )
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

function table.bubbleSort( T, func, maxchange )
	local count = #T
	local changed
	local changecount = 0
	repeat
		changed = false
		count = count - 1
		for i = 1, count do
			if func( T[i], T[i + 1] ) then
				T[i], T[i + 1] = T[i + 1], T[i]
				changed = true
				changecount = changecount + 1
				if ( maxchange and changecount >= maxchange ) then
					print( changecount )
					return
				end
			end
		end
	until ( changed == false )
	print( changecount )
end

-- local T = {
	-- 6,
	-- 5,
	-- 8,
	-- 2,
	-- 4,
	-- 3,
	-- 7,
	-- 9,
	-- 1,
-- }
-- PrintTable( T )
-- table.bubbleSort( T, function( a, b )
	-- return a > b
-- end )
-- PrintTable( T )

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
