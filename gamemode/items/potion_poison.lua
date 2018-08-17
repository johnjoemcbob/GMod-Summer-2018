PRK_AddItem( "Potion_Posion", "Base_Potion", {
	PrettyName = "Poison",
	Price = 1,
	Colour = Color( 10, 10, 10, 255 ),
	InitServer = function( info, self )
		info.base.InitServer( info, self )
	end,
	Use = function( info, ply )
		info.base.Use( info, ply )

		if ( SERVER ) then
			PRK_OverrideDeathMessage( ply, {
				"POISON",
				"YOUR OWN CURIOSITY",
				"YOUR OWN STUPIDITY",
				"SPOILED BITER MILK",
			} )
				ply:TakeDamage( 1, ply, ply )
			PRK_OverrideDeathMessage( ply, nil )
		end

		return true
	end,
} )
