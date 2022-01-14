PRK_AddItem( "Bullet", "", {
	PrettyName = "Bullet",
	Price = 40,
	SpawnOverride = function( info, pos )
		local ent = ents.Create( "prk_bullet_heavy" )
		ent:SetPos( pos )
		ent:Spawn()
		return ent
	end,
} )
