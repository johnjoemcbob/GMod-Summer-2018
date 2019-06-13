--
-- Prickly Summer 2018
-- 15/08/18
--
-- Shared Use Items
--

PRK_Items = {}
local PRK_ItemsToLoad = {}
function PRK_AddItem( name, base, data )
	if ( !PRK_Items ) then PRK_Items = {} end

	PRK_Items[name] = {}
		-- Base item
		-- print( "base; " .. base )
		if ( base and base != "" ) then
			-- print( PRK_Items[base] )
			if ( !PRK_Items[base] ) then
				print( "hasn't loaded base: " .. base .. " yet... waiting..." )
				table.insert( PRK_ItemsToLoad, { name, base, data } )
				return false
			end
			PRK_Items[name] = table.shallowcopy( PRK_Items[name] )
			data.base = PRK_Items[base]

			-- Pass unique down to inherit table
			for key, value in pairs( data.base ) do
				if ( data[key] == nil ) then
					-- print( key .. " " .. tostring( data[key] ) )
					data[key] = value
				end
			end
		end
	table.Merge( PRK_Items[name], data )
	-- PrintTable( PRK_Items[name] )

	return true
end

PRK_BulletTypeInfo = {}
local PRK_BulletsToLoad = {}
function PRK_AddBullet( name, base, data )
	if ( !PRK_BulletTypeInfo ) then PRK_BulletTypeInfo = {} end

	PRK_BulletTypeInfo[name] = {}
		-- Base item
		if ( base and base != "" ) then
			if ( !PRK_BulletTypeInfo[name] ) then
				print( "hasn't loaded base: " .. name .. " yet... waiting..." )
				table.insert( PRK_BulletsToLoad, { name, base, data } )
				return false
			end
			PRK_BulletTypeInfo[name] = table.shallowcopy( PRK_BulletTypeInfo[base] )
			data.base = PRK_BulletTypeInfo[base]
		end
	table.Merge( PRK_BulletTypeInfo[name], data )
	-- PrintTable( PRK_BulletTypeInfo[name] )

	return true
end

-- Load use items last
function PRK_Load_Items( localdir )
	-- Try load all first
	PRK_Load_Item_Files( localdir )

	-- Now handle any items which depended upon a non-existent base
	while ( #PRK_ItemsToLoad > 0 ) do
		local item = PRK_ItemsToLoad[1]
		PRK_AddItem( item[1], item[2], item[3] )
		print( "Try late load; " .. item[1] )
		table.remove( PRK_ItemsToLoad, 1 )
	end
	-- Now handle any bullets which depended upon a non-existent base
	while ( #PRK_BulletsToLoad > 0 ) do
		local item = PRK_BulletsToLoad[1]
		PRK_AddBullet( item[1], item[2], item[3] )
		print( "Try late load; " .. item[1] )
		table.remove( PRK_BulletsToLoad, 1 )
	end

	-- PrintTable( PRK_Items )
end

local folder = "items/"
local dir = PRK_GamemodePath .. "gamemode/" .. folder
function PRK_Load_Item_Files( localdir )
	local srchpath = localdir .. "*"
	print( srchpath )
	local files, directories = file.Find( srchpath, "GAME" )
	for k, file in pairs( files ) do
		local res = folder .. string.gsub( localdir .. file, dir, "" )
		print( res )
		if ( SERVER ) then
			AddCSLuaFile( res )
		end
		include( res )
	end
	for k, dir in pairs( directories ) do
		PRK_Load_Items( localdir .. dir .. "/" )
	end
end

print( "----------------" )
print( "Load Use Items..." )
PRK_Load_Items( dir )
print( "Finish Use Items..." )
print( "----------------" )
PrintTable( PRK_BulletTypeInfo )

function PRK_GetItem( ply )
	local item = ply:GetNWString( "PRK_Item", "" )
		if ( item == "" ) then
			item = nil
		end
	return item
end

if ( CLIENT ) then
	net.Receive( "PRK_Item_Use", function( len, ply )
		local name = net.ReadString()

		PRK_Items[name]:Use( LocalPlayer() )
	end )
end

if ( SERVER ) then
	-- Net
	util.AddNetworkString( "PRK_Item_Use" )

	function PRK_SendItemUse( ply, name )
		net.Start( "PRK_Item_Use" )
			net.WriteString( name )
		net.Send( ply )
	end

	function PRK_SpawnItem( name, pos )
		if ( !name ) then
			local possible = table.shallowcopy( PRK_Items )
				for key, v in pairs( possible ) do
					if ( string.find( key, "Base" ) ) then
						possible[key] = nil
					end
				end
			null, name = TableRandom( possible )
		end

		local ent = ents.Create( "prk_item" )
			ent:SetPos( pos )
			ent:SetItem( name )
			ent:Spawn()
		return ent
	end

	function PRK_PickupItem( ply, name, ent )
		-- Drop any old held items first
		if ( PRK_GetItem( ply ) ) then
			PRK_DropItem( ply )
		end

		-- Pickup and remove new item
		PRK_SetItem( ply, name )
		ply.PRK_Item_Cooldown = ent.Cooldown
		ent:Remove()
	end

	function PRK_DropItem( ply )
		if ( PRK_GetItem( ply ) ) then
			-- Spawn item back in world
			local dir = ply:EyeAngles():Forward()
				-- dir.z = dir.z / 3
			local pos = ply:EyePos() + dir * 80
				local tr = util.TraceLine( {
					start = ply:EyePos(),
					endpos = pos,
					filter = { ply },
				} )
				if ( tr.Hit ) then
					pos = tr.HitPos - tr.HitNormal * 2
				end
			local item = PRK_SpawnItem( PRK_GetItem( ply ), pos )
			item.Cooldown = ply.PRK_Item_Cooldown
			item:SetZone( ply:GetNWInt( "PRK_Zone", 0 ) )
			local phys = item:GetPhysicsObject()
			if ( phys and phys:IsValid() ) then
				phys:AddAngleVelocity( VectorRand() * 1000 )
				phys:AddVelocity( dir * 300 )
			end

			-- Remove held item
			PRK_SetItem( ply, "" )
			ply.PRK_Item_Cooldown = 0
		end
	end

	function PRK_UseItem( ply )
		if ( ply.PRK_Item_Cooldown and ply.PRK_Item_Cooldown > CurTime() ) then return end

		if ( PRK_GetItem( ply ) ) then
			-- Disable item-drop-on-death in case this caused the player's death
			ply.PRK_Item_DisableDropOnDeath = PRK_Items[PRK_GetItem( ply )].DisableDropOnSelfDeath

			-- Use effect
			PRK_SendItemUse( ply, PRK_GetItem( ply ) )
			local remove = PRK_Items[PRK_GetItem( ply )]:Use( ply )
			if ( PRK_GetItem( ply ) ) then -- Catch in case of death
				ply.PRK_Item_Cooldown = CurTime() + ( PRK_Items[PRK_GetItem( ply )].Cooldown or 0 )
			end

			-- Remove from held
			if ( remove ) then
				PRK_SetItem( ply, "" )
			end
			ply.PRK_Item_DisableDropOnDeath = nil
		end
	end

	function PRK_SetItem( ply, name )
		ply:SetNWString( "PRK_Item", name )
	end
end
