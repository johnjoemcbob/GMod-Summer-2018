AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

ENT.SpeedFire = 70

function ENT:ExtraInitialize()
	self.Head:SetModel( "models/hunter/blocks/cube1x1x05.mdl" )
end

function ENT:DoFire()
	if ( !self.NextFire or self.NextFire <= CurTime() ) then
		-- Fire projectile
		local bullet = ents.Create( "prk_rocket" )
		bullet:Spawn()
			local dir = ( self.Target:GetPos() - self:GetPos() ):GetNormalized()
				dir.z = 0
			bullet:Launch(
				self.Barrel:GetPos(),
				dir * self.SpeedFire,
				false
			)
			bullet.DamageEndCallback = function( self )
				self:Remove()
			end
		bullet.Owner = self
		bullet:SetZone( self.Zone )
		timer.Simple( self.TimeAutoRemoveLaser, function()
			if ( bullet and bullet:IsValid() ) then
				bullet:Remove()
			end
		end )

		-- Play sound
		self.Barrel:EmitSound( self.Sound_Fire, 75, math.random( 150, 255 ) )

		-- Force to find a new target now
		self.Target = nil

		self.NextFire = CurTime() + self.TimeFire
	end

	if ( self.Sound_Rotate:IsPlaying() ) then
		self.Rotator:EmitSound( self.Sound_StopRotate, 75, 100 + math.random( -5, 5 ), 0.5 )
		self.Sound_Rotate:Stop()
	end
end
