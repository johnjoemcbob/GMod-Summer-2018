PRK_AddBullet( "Gold", "", {
	Paint = function( info, self, x, y, r )
		
	end,
	CanFire = function( info, self )
		return true
	end,
	Fire = function( info, self )
		return false, false, true, true
	end,
} )
