PRK_AddBullet( "Empty", "", {
	Paint = function( info, self, x, y, r )
		
	end,
	CanFire = function( info, self )
		if ( !self.NextEmptySpin or self.NextEmptySpin <= CurTime() ) then
			self.Owner:SetNWInt( "PRK_CurrentChamber", math.Wrap( self.Owner:GetNWInt( "PRK_CurrentChamber" ) - 1, 1, self.MaxClip ) )
			self:SpinSound()
			if ( SERVER ) then
				self:SendChamberWarning( math.Wrap( self.Owner:GetNWInt( "PRK_CurrentChamber" ) + 1, 1, self.MaxClip ) )
				self:SendReload( -1 )
			end

			self.NextEmptySpin = CurTime() + self.TimeReload
		end
		return false
	end,
	Fire = function( info, self )
		return false, false, true, true
	end,
} )
