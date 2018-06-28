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
PRK_HUD_Colour_Main					= Color( 255, 255, 255, 255 )
PRK_HUD_Colour_Dark					= Color( 0, 0, 0, 255 )
PRK_HUD_Colour_Money				= Color( 255, 255, 50, 255 )
PRK_HUD_Colour_Shadow				= Color( 255, 100, 150, 255 )
PRK_HUD_Colour_Highlight			= Color( 100, 190, 190, 255 )
PRK_Colour_Enemy_Skin				= Color( 0, 0, 5, 255 )
PRK_Colour_Enemy_Eye				= PRK_HUD_Colour_Shadow
PRK_Colour_Enemy_Tooth				= PRK_HUD_Colour_Main
PRK_Colour_Enemy_Mouth				= Color( 100, 100, 100, 255 )
PRK_Grass_Mesh_CountRange			= { 1, 6 } -- { 0, 2 }
PRK_Grass_Billboard_Count			= 100
PRK_Grass_Billboard_DrawRange		= 1000
PRK_Grass_Billboard_SortRange		= 10
PRK_Grass_Billboard_ShouldDrawTime	= 1
PRK_Grass_Billboard_MaxSortCount	= 0
PRK_Grass_Billboard_MaxRenderCount	= 10000
PRK_Gen_SizeModifier				= 10
PRK_CurrencyBefore					= "€"
PRK_CurrencyAfter					= ""
PRK_CursorSize						= 8
PRK_Plate_Size						= 47.45
PRK_Speed							= 600
PRK_Jump							= 0

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
