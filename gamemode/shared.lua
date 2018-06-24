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
PRK_Plate_Size = 47.45
PRK_Speed	= 600
PRK_Jump	= 0

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
