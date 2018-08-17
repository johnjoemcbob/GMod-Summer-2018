PRK_AddItem( "Potion_Health", "Base_Potion", {
	PrettyName = "Health Potion",
	-- KillName = "POTION",
	-- UseLabel = "PICK UP",
	Colour = Color( 255, 100, 100, 255 ),
	InitServer = function( info, self )
		info.base:InitServer( self )
		-- self:SetColor( Color( 255, 100, 100, 255 ) )
	end,
	Use = function( info, ply )
		info.base:Use( ply )

		if ( SERVER ) then
			local heal = 2 -- One full heart = 2hp
			ply:SetHealth( math.min( ply:Health() + heal, ply:GetMaxHealth() ) )
		end

		return true
	end,
} )
