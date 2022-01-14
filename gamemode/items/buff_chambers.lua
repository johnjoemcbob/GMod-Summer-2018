
PRK_AddItem( "Chambers Buff", "", {
	PrettyName = "++ Chambers",
	KillName = "BUFF",
	UseLabel = "TAKE",
	Price = 70,
	Cooldown = 0.1,
	Digital = true,
	OnBuy = function( info, ply )
        local gun = ply:GetActiveWeapon()
		gun:AddChambers( 1 )
	end,
} )
