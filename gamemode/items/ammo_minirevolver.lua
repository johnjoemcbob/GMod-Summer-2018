local scale = 0.2

PRK_AddItem( "Mini Revolver Ammo", "Base_Ammo", {
	PrettyName = "Mini Revolver Ammo",
	KillName = "AMMO",
	UseLabel = "TAKE",
	Price = 20,
	Cooldown = 0.1,
	Use = function( info, ply )
		if ( SERVER ) then
			-- Load ammo into next available clip
			ply:GetActiveWeapon():LoadBullet( 0, "Mini Revolver" )
		end

		return true
	end,
	SendData = function( info, self )
		-- To send any info from server to client
	end,
} )
