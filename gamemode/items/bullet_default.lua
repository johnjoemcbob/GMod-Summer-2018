PRK_AddBullet( "Default", "", {
	Paint = function( info, self, x, y, r )
		local r = r * 3
		draw.Rect( x - r / 2, y - r / 2, r, r, Color( 100, 190, 190, 255 ) )
	end,
	CanFire = function( info )
		return true
	end,
	Fire = function( info, self )
		-- Play shoot sound
		self:EmitSound(
			"weapons/grenade_launcher1.wav",
			75,
			self.SoundPitchFireBase + ( self.SoundPitchFireIncrease * ( 1 - ( self:GetFilledChamberCount() / self.MaxClip ) ) )
		)

		-- Play first impact effect at spawn point
		local tr = self.Owner:GetEyeTrace()
		local effectdata = EffectData()
			local pos = tr.HitPos
			effectdata:SetOrigin( pos )
			effectdata:SetNormal( tr.HitNormal )
		util.Effect( "prk_hit", effectdata )

		-- Spawn bullet
		if ( SERVER ) then
			local bullet = ents.Create( "prk_bullet_heavy" )
			bullet.Owner = self.Owner
			bullet:Spawn()
			-- Appear at hit point and bounce back towards player
			local out = 10
			local pos = tr.HitPos + tr.HitNormal * out
				-- Clamp pos to max distance
				local dir = pos - self.Owner:EyePos()
				if ( dir:LengthSqr() > self.MaxDistanceSqr ) then
					pos = self.Owner:GetPos() + dir:GetNormalized() * self.MaxDistance
				end
			local mult = 8000
			local dir = ( self.Owner:EyePos() + Vector( 0, 0, 100 ) - tr.HitPos ):GetNormalized() * mult * 3
			bullet:Launch( pos, dir )
			local phys = bullet:GetPhysicsObject()
			if ( phys and phys:IsValid() ) then
				phys:AddAngleVelocity( VectorRand() * 1000 )
			end
			bullet:CollideWithEnt( tr.Entity )
			bullet:SetZone( self.Owner:GetNWInt( "PRK_Zone", 0 ) )
		end

		-- return takeammo, spin, shootparticles, punch
		return true, true, true, true
	end,
} )
