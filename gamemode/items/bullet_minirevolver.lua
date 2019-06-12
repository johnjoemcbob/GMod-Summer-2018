PRK_AddBullet( "Mini Revolver", "", {
	Paint = function( info, self, x, y, r )
		-- Initialise
		if ( !self.Fires ) then
			self.Fires = 6
		end

		local r = r * 3
		draw.Rect( x - r / 2, y - r / 2, r, r, Color( 210, 210, 220, 255 ) )

		local ang = 0
		local chambers = 6
		local cham_rad = r / 16
		local points = PRK_GetCirclePoints( x, y, r - cham_rad * 13, chambers, ang )
			-- Remove middle point
			table.remove( points, 1 )
		for chamber, point in pairs( points ) do
			if ( chamber <= self.Fires ) then
				surface.SetDrawColor( 100, 190, 190, 255 )
			else
				surface.SetDrawColor( 10, 10, 20, 255 )
			end
			draw.Circle( point.x, point.y, math.min( 18, cham_rad ), 32, 0 )
		end
	end,
	CanFire = function( info )
		return true
	end,
	Fire = function( info, self )
		-- Initialise
		if ( !self.Fires ) then
			self.Fires = 6
		end

		-- Play shoot sound
		self:EmitSound(
			"weapons/grenade_launcher1.wav",
			75,
			50 + self.SoundPitchFireBase + ( self.SoundPitchFireIncrease * ( 1 - ( self.Fires / 6 ) ) )
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
			bullet:Spawn()
			bullet.Owner = self.Owner
			local scale = 0.5
				PRK_ResizePhysics( bullet, scale )
				bullet:SendScale( scale )
			bullet.CanPickup = false
			-- Appear at hit point and bounce back towards player
			local pos = tr.HitPos + tr.HitNormal * 10
				-- Clamp pos to max distance
				local dir = pos - self.Owner:EyePos()
				if ( dir:LengthSqr() > self.MaxDistanceSqr ) then
					pos = self.Owner:GetPos() + dir:GetNormalized() * self.MaxDistance
				end
			local dir = ( self.Owner:EyePos() + Vector( 0, 0, 100 ) - tr.HitPos ):GetNormalized() * 8000 * 3
			bullet:Launch( pos, dir )
			local phys = bullet:GetPhysicsObject()
			if ( phys and phys:IsValid() ) then
				phys:EnableMotion( true )
				phys:AddAngleVelocity( VectorRand() * 1000 )
			end
			bullet:CollideWithEnt( tr.Entity )
			bullet:SetZone( self.Owner:GetNWInt( "PRK_Zone", 0 ) )
		end

		self.Fires = self.Fires - 1
		if ( self.Fires <= 0 ) then
			return true, true, true, true
		end
		-- return takeammo, spin, shootparticles, punch
		return false, false, true, true
	end,
} )
