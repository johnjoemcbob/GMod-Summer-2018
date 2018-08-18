PRK_AddItem( "Potion_Boom", "Base_Potion", {
	PrettyName = "Boom Bottle",
	Price = 2,
	Colour = Color( 10, 10, 10, 255 ),
	InitServer = function( info, self )
		info.base.InitServer( info, self )
	end,
	Use = function( info, ply )
		info.base.Use( info, ply )

		if ( SERVER ) then
			PRK_OverrideDeathMessage( player.GetAll(), {
				"AN EXPLOSION IN A BOTTLE",
				"BOTTLED SPLODER ESSENCE",
				"A BIG BOOM",
				"A BIG BANG",
				"YOUR OWN CURIOSITY",
				"YOUR OWN STUPIDITY",
				"ESPECIALLY POTENT WHISKEY",
			} )
				PRK_Explosion( ply, ply:GetPos(), 200 )
			PRK_OverrideDeathMessage( player.GetAll(), nil )
		end

		return true
	end,
} )
