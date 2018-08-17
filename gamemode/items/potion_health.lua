PRK_AddItem( "Potion_Health", "Base_Potion", {
	PrettyName = "Health Potion",
	Price = 15,
	Colour = Color( 255, 50, 50, 255 ),
	InitServer = function( info, self )
		info.base.InitServer( info, self )
	end,
	Use = function( info, ply )
		info.base.Use( info, ply )

		if ( SERVER ) then
			local heal = 2 -- One full heart = 2hp
			ply:SetHealth( math.min( ply:Health() + heal, ply:GetMaxHealth() ) )
		end

		return true
	end,
} )
