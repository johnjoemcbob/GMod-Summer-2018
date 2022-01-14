local col = Color( 255, 100, 190, 255 )
local hearttime = 0.2
local heartspeed = 15
local heartsize = 1

if ( SERVER ) then
	util.AddNetworkString( "PRK_Bullet_Lobby" )

	function PRK_Send_Bullet_Lobby( pos, ang )
		net.Start( "PRK_Bullet_Lobby" )
			net.WriteVector( pos )
			net.WriteAngle( ang )
		net.Broadcast()
	end
end
if ( CLIENT ) then
	local hearts = {}
	net.Receive( "PRK_Bullet_Lobby", function( len )
		local pos = net.ReadVector()
		local ang = net.ReadAngle()

		-- Play blood effect
		local effectdata = EffectData()
			effectdata:SetOrigin( pos )
			effectdata:SetNormal( ang:Forward() * 2 )
			effectdata:SetStart( ColourToVector( col ) )
			effectdata:SetScale( 0 )
		util.Effect( "prk_blood", effectdata )

		-- Add heart
		table.insert( hearts, {
			lifetime = CurTime() + hearttime,
			pos = pos,
			ang = ang,
			siz = 0,
		} )
	end )

	hook.Add( "PreDrawTranslucentRenderables", "PRK_PreDrawTranslucentRenderables_Grass", function( depth, skybox )
		if ( !PRK_ShouldDraw() ) then return end
		if ( depth or skybox ) then return end

		local r = 32
		local toremove = {}
		for key, heart in pairs( hearts ) do
			if ( heart.lifetime < CurTime() ) then
				table.insert( toremove, key )
			else
				-- Move
				heart.pos = heart.pos + heart.ang:Forward() * heartspeed
				heart.siz = math.Approach( heart.siz, heartsize, FrameTime() * heartspeed )

				-- Render
				local function ren( ang )
					cam.Start3D2D( heart.pos, ang, heart.siz )
						surface.SetDrawColor( col )
						draw.Heart( 0, 0, ( r / 2 ), 16 )
					cam.End3D2D()
				end
				local ang = heart.ang - Angle()
					ang:RotateAroundAxis( heart.ang:Up(), -90 )
					ang:RotateAroundAxis( heart.ang:Right(), 90 )
				ren( ang )
				-- Drap other size
					ang:RotateAroundAxis( heart.ang:Right(), 180 )
					ang:RotateAroundAxis( heart.ang:Forward(), 180 )
				ren( ang )
			end
		end
		for k, key in pairs( toremove ) do
			table.remove( hearts, key )
		end
	end )
end

PRK_AddBullet( "Lobby", "", {
	Paint = function( info, self, x, y, r )
		local fade = Color( col.r, col.g, col.b, 20 )
		draw.Rect( x - r, y - r, r * 2, r * 2, fade )
		surface.SetDrawColor( col )
		draw.Heart( x, y, r / 2, 16 )
	end,
	CanFire = function( info )
		return true
	end,
	Fire = function( info, self )
		-- Play shoot sound
		self:EmitSound(
			"weapons/grenade_launcher1.wav",
			75,
			50 + self.SoundPitchFireBase + ( self.SoundPitchFireIncrease )
		)

		-- Broadcast heart effect to all players
		if ( SERVER ) then
			PRK_Send_Bullet_Lobby( self.Owner:EyePos(), self.Owner:EyeAngles() )
		end

		-- return takeammo, spin, shootparticles, punch
		return false, true, true, true
	end,
} )
