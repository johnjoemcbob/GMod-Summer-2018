--
-- Prickly Summer 2018
-- 15/08/18
--
-- Shared Use Items
--

PRK_Items = {}
function PRK_AddItem( name, base, data )
	local function load()
		PRK_Items[name] = {}
			-- Base item
			if ( base and base != "" ) then
				if ( !PRK_Items[name] ) then
					print( "hasn't loaded base: " .. name .. " yet... waiting..." )
					timer.Simple( 1, function() load() end )
					return
				end
				PRK_Items[name] = table.shallowcopy( PRK_Items[base] )
				data.base = PRK_Items[base]
			end
		table.Merge( PRK_Items[name], data )
		PrintTable( PRK_Items[name] )
	end
	load()
end

function PRK_GetItem( ply )
	local item = ply:GetNWString( "PRK_Item", "" )
		if ( item == "" ) then
			item = nil
		end
	return item
end

-- Load use items last
local folder = "items/"
local dir = PRK_GamemodePath .. "gamemode/" .. folder
function PRK_Load_Items( localdir )
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
